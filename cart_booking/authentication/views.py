from django.shortcuts import render
from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import get_user_model, authenticate
from .serializers import UserSerializer
from rest_framework.permissions import AllowAny
from django.core.mail import send_mail
import random
from rest_framework_simplejwt.tokens import RefreshToken
from django.views.generic import TemplateView
from twilio.rest import Client
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import requests
from firebase_admin import auth
from django.core.cache import cache
from rest_framework.exceptions import Throttled
from .models import CustomUser

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = UserSerializer

    def create(self, request, *args, **kwargs):
        try:
            data = {
                'email': request.POST.get('email'),
                'password': request.POST.get('password'),
                'password2': request.POST.get('password2'),
                'name': request.POST.get('name'),
                'mobile': request.POST.get('mobile'),
            }
            
            if 'id_card' in request.FILES:
                data['id_card'] = request.FILES['id_card']

            serializer = self.get_serializer(data=data)
            if serializer.is_valid():
                user = serializer.save()
                # Since email is already verified before registration, mark as verified
                user.is_verified = True
                user.save()
                
                return Response({
                    "message": "User Created Successfully.",
                    "email": user.email
                }, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Registration error: {str(e)}")
            return Response({
                "message": "An error occurred during registration.",
                "error": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class VerifyEmailView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        
        try:
            # First check if this is a pre-signup verification
            cache_key = f"pre_signup_otp_{email}"
            cached_data = cache.get(cache_key)
            
            if cached_data:
                cached_otp = cached_data['otp']
                created_at = timezone.datetime.fromisoformat(cached_data['created_at'])
                
                # Check if OTP is expired
                if (timezone.now() - created_at) > timedelta(minutes=5):
                    cache.delete(cache_key)
                    return Response({
                        "message": "OTP has expired. Please request a new one.",
                        "expired": True
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                if otp == cached_otp:
                    # Clear the OTP from cache
                    cache.delete(cache_key)
                    return Response({"message": "Email verified successfully"}, status=status.HTTP_200_OK)
                return Response({"message": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)
            
            # If not in cache, check if this is a post-signup verification
            user = User.objects.get(email=email)
            
            # Check if OTP is expired
            if user.otp_created_at and (timezone.now() - user.otp_created_at) > timedelta(minutes=5):
                return Response({
                    "message": "OTP has expired. Please request a new one.",
                    "expired": True
                }, status=status.HTTP_400_BAD_REQUEST)
                
            if user.otp == otp:
                user.is_verified = True
                user.otp = None  # Clear OTP after successful verification
                user.otp_created_at = None
                user.save()
                return Response({"message": "Email verified successfully"}, status=status.HTTP_200_OK)
            return Response({"message": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)
        except User.DoesNotExist:
            return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)

class LoginView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')

        user = authenticate(username=email, password=password)
        
        if user is not None:
            if user.is_verified:
                refresh = RefreshToken.for_user(user)
                return Response({
                    'message': 'Login successful',
                    'tokens': {
                        'refresh': str(refresh),
                        'access': str(refresh.access_token),
                    }
                }, status=status.HTTP_200_OK)
            return Response({'message': 'Please verify your email first'}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'message': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class RequestPasswordResetView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        try:
            user = User.objects.get(email=email)
            otp = str(random.randint(100000, 999999))
            user.reset_otp = otp
            user.reset_otp_created_at = timezone.now()
            user.save()
            
            send_mail(
                'Reset your password',
                f'Your password reset OTP is: {otp}\nThis OTP will expire in 5 minutes.',
                'chalo.kart101@gmail.com',
                [email],
                fail_silently=False,
            )
            return Response({"message": "Password reset OTP sent. Please use it within 5 minutes."}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)

class ResetPasswordConfirmView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        new_password = request.data.get('new_password')
        
        try:
            user = User.objects.get(email=email)
            
            # Check if reset OTP is expired
            if user.reset_otp_created_at and (timezone.now() - user.reset_otp_created_at) > timedelta(minutes=5):
                return Response({
                    "message": "Reset OTP has expired. Please request a new one.",
                    "expired": True
                }, status=status.HTTP_400_BAD_REQUEST)
                
            if user.reset_otp == otp:
                user.set_password(new_password)
                user.reset_otp = None  # Clear the OTP after use
                user.reset_otp_created_at = None
                user.save()
                return Response({"message": "Password reset successful"}, status=status.HTTP_200_OK)
            return Response({"message": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)
        except User.DoesNotExist:
            return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)

class ResendVerificationView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        try:
            user = User.objects.get(email=email)
            if not user.is_verified:
                # Check if previous OTP was sent less than 30 seconds ago
                if user.otp_created_at and (timezone.now() - user.otp_created_at) < timedelta(seconds=30):
                    time_left = 30 - (timezone.now() - user.otp_created_at).seconds
                    return Response({
                        "message": f"Please wait {time_left} seconds before requesting a new OTP",
                        "wait_time": time_left
                    }, status=status.HTTP_400_BAD_REQUEST)

                otp = str(random.randint(100000, 999999))
                user.otp = otp
                user.otp_created_at = timezone.now()
                user.save()
                
                send_mail(
                    'Verify your email',
                    f'Your new OTP is: {otp}\nThis OTP will expire in 5 minutes.',
                    'chalo.kart101@gmail.com',
                    [email],
                    fail_silently=False,
                )
                return Response({"message": "New OTP sent successfully. Please verify within 5 minutes."}, status=status.HTTP_200_OK)
            return Response({"message": "Email is already verified"}, status=status.HTTP_400_BAD_REQUEST)
        except User.DoesNotExist:
            return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)

class SendEmailVerificationView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        
        # Check if email already exists
        if User.objects.filter(email=email).exists():
            return Response({
                "message": "Email already registered",
                "error": "Email already exists"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate OTP
        otp = str(random.randint(100000, 999999))
        
        # Store OTP in cache with 5-minute expiry
        cache_key = f"pre_signup_otp_{email}"
        cache.set(cache_key, {
            'otp': otp,
            'created_at': timezone.now().isoformat()
        }, timeout=300)  # 5 minutes
        
        try:
            send_mail(
                'Verify your email',
                f'Your OTP is: {otp}\nThis OTP will expire in 5 minutes.',
                'chalo.kart101@gmail.com',
                [email],
                fail_silently=False,
            )
            return Response({
                "message": "Verification email sent successfully. Please verify within 5 minutes.",
                "email": email
            }, status=status.HTTP_200_OK)
        except Exception as e:
            cache.delete(cache_key)
            return Response({
                "message": "Failed to send verification email",
                "error": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class FirebasePhoneAuthView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        try:
            id_token = request.data.get('id_token')
            if not id_token:
                return Response({'error': 'ID token is required'}, status=status.HTTP_400_BAD_REQUEST)

            # Verify the Firebase token
            decoded_token = auth.verify_id_token(id_token)
            phone_number = decoded_token.get('phone_number')

            if not phone_number:
                return Response({'error': 'Phone number not found in token'}, status=status.HTTP_400_BAD_REQUEST)

            # Get or create user
            user, created = CustomUser.objects.get_or_create(
                phone_number=phone_number,
                defaults={
                    'username': f'user_{phone_number.replace("+", "")}',
                    'email': f'user_{phone_number.replace("+", "")}@temp.com',
                    'is_phone_verified': True
                }
            )

            if not created:
                user.is_phone_verified = True
                user.save()

            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'Phone number verified successfully',
                'user_id': user.id,
                'phone_number': phone_number,
                'access_token': str(refresh.access_token),
                'refresh_token': str(refresh),
            }, status=status.HTTP_200_OK)

        except auth.InvalidIdTokenError:
            return Response({'error': 'Invalid Firebase token'}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class OTPTestView(TemplateView):
    template_name = 'otp_test.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['firebase_api_key'] = settings.FIREBASE_WEB_API_KEY
        return context

class FirebasePhoneTestView(TemplateView):
    template_name = 'firebase_phone_test.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Add your Firebase configuration from settings
        context['firebase_config'] = {
            'apiKey': settings.FIREBASE_API_KEY,
            'authDomain': settings.FIREBASE_AUTH_DOMAIN,
            'projectId': settings.FIREBASE_PROJECT_ID,
            'storageBucket': settings.FIREBASE_STORAGE_BUCKET,
            'messagingSenderId': settings.FIREBASE_MESSAGING_SENDER_ID,
            'appId': settings.FIREBASE_APP_ID
        }
        return context
