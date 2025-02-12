from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.exceptions import PermissionDenied
from django_filters.rest_framework import DjangoFilterBackend
from datetime import datetime, timedelta
from decimal import Decimal
from .models import User, Customer, Driver, Trip, Wallet, Payment, Route, GolfCart
from .serializers import (
    UserSerializer, CustomerSerializer, DriverSerializer,
    TripSerializer, WalletSerializer, PaymentSerializer,
    RouteSerializer, GolfCartSerializer
)
import logging
from django.db.models import Avg, Sum
from django.utils import timezone
from django.db import transaction

logger = logging.getLogger(__name__)

class BaseViewSet(viewsets.ModelViewSet):
    def handle_exception(self, exc):
        logger.error(f"Error in {self.__class__.__name__}: {str(exc)}")
        return super().handle_exception(exc)

class UserViewSet(BaseViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['user_name', 'email', 'phone']
    
    def get_permissions(self):
        if self.action in ['login', 'register']:
            return []
        if self.action in ['list', 'destroy']:
            return [IsAdminUser()]
        return [IsAuthenticated()]
    
    @action(detail=False, methods=['post'])
    def login(self, request):
        try:
            email = request.data.get('email')
            password = request.data.get('password')
            
            if not email or not password:
                return Response(
                    {'error': 'Email and password are required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                user = User.objects.get(email=email)
                if not user.is_active:
                    return Response(
                        {'error': 'Account is deactivated'},
                        status=status.HTTP_403_FORBIDDEN
                    )
                
                # Use Django's built-in password hashing
                from django.contrib.auth.hashers import check_password, make_password
                if not check_password(password, user.password):
                    return Response(
                        {'error': 'Invalid credentials'},
                        status=status.HTTP_401_UNAUTHORIZED
                    )
                    
                serializer = self.get_serializer(user)
                return Response({
                    'token': 'dummy_token',  # Replace with proper JWT token
                    'user': serializer.data
                })
            except User.DoesNotExist:
                return Response(
                    {'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            return Response(
                {'error': 'An error occurred during login'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def register(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            try:
                user = serializer.save()
                logger.info(f"User registered successfully: {user.email}")
                return Response({
                    'message': 'User registered successfully',
                    'user': serializer.data
                }, status=status.HTTP_201_CREATED)
            except Exception as e:
                logger.error(f"Registration error: {str(e)}")
                return Response(
                    {'error': 'Registration failed'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def change_password(self, request, pk=None):
        user = self.get_object()
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        
        if not old_password or not new_password:
            return Response(
                {'error': 'Both old and new passwords are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if user.password != old_password:
            return Response(
                {'error': 'Invalid old password'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if len(new_password) < 8:
            return Response(
                {'error': 'Password must be at least 8 characters long'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user.password = new_password
            user.save()
            return Response({'message': 'Password changed successfully'})
        except Exception as e:
            logger.error(f"Password change error: {str(e)}")
            return Response(
                {'error': 'Failed to change password'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        user = self.get_object()
        user.is_active = False
        user.save()
        return Response({'message': 'Account deactivated successfully'})

class CustomerViewSet(BaseViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['is_student']
    search_fields = ['user_name', 'email']

    @action(detail=True, methods=['get'])
    def trip_history(self, request, pk=None):
        try:
            customer = self.get_object()
            page = self.paginate_queryset(
                Trip.objects.filter(customer=customer).order_by('-start_time')
            )
            serializer = TripSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        except Exception as e:
            logger.error(f"Trip history error: {str(e)}")
            return Response(
                {'error': 'Failed to fetch trip history'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def verify_student(self, request, pk=None):
        customer = self.get_object()
        govt_id = request.data.get('govt_id')
        if not govt_id:
            return Response(
                {'error': 'Government ID required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            customer.govt_id = govt_id
            customer.is_student = True
            customer.save()
            return Response({'message': 'Student status verified'})
        except Exception as e:
            logger.error(f"Student verification error: {str(e)}")
            return Response(
                {'error': 'Failed to verify student status'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class DriverViewSet(BaseViewSet):
    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['user_name', 'driving_license']

    @action(detail=True, methods=['post'])
    def toggle_availability(self, request, pk=None):
        driver = self.get_object()
        is_available = request.data.get('is_available', False)
        
        if not driver.golf_cart:
            return Response(
                {'error': 'No golf cart assigned'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            driver.is_available = is_available
            driver.golf_cart.status = 'ACTIVE' if is_available else 'INACTIVE'
            driver.golf_cart.save()
            driver.save()
            return Response({
                'status': driver.golf_cart.status,
                'is_available': driver.is_available
            })
        except Exception as e:
            logger.error(f"Toggle availability error: {str(e)}")
            return Response(
                {'error': 'Failed to update availability'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['get'])
    def earnings_report(self, request, pk=None):
        driver = self.get_object()
        period = request.query_params.get('period', 'week')
        
        try:
            if period == 'week':
                start_date = datetime.now() - timedelta(days=7)
            elif period == 'month':
                start_date = datetime.now() - timedelta(days=30)
            else:
                start_date = datetime.now() - timedelta(days=365)
                
            completed_trips = Trip.objects.filter(
                driver=driver,
                end_time__gte=start_date,
                status='COMPLETED'
            )
            
            total_earnings = sum(trip.fare for trip in completed_trips)
            total_trips = completed_trips.count()
            average_rating = completed_trips.exclude(rating__isnull=True).aggregate(
                Avg('rating')
            )['rating__avg'] or 0
            
            return Response({
                'period': period,
                'total_earnings': str(total_earnings),
                'total_trips': total_trips,
                'average_rating': round(average_rating, 2),
                'completed_trips': TripSerializer(completed_trips, many=True).data
            })
        except Exception as e:
            logger.error(f"Earnings report error: {str(e)}")
            return Response(
                {'error': 'Failed to generate earnings report'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TripViewSet(BaseViewSet):
    queryset = Trip.objects.all()
    serializer_class = TripSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status']

    def perform_create(self, serializer):
        trip = serializer.save()
        trip.fare = trip.calculate_fare()
        trip.save()

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        trip = self.get_object()
        if trip.status in ['COMPLETED', 'CANCELLED']:
            return Response(
                {'error': 'Cannot cancel this trip'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            trip.status = 'CANCELLED'
            trip.save()
            return Response({'message': 'Trip cancelled successfully'})
        except Exception as e:
            logger.error(f"Trip cancellation error: {str(e)}")
            return Response(
                {'error': 'Failed to cancel trip'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def rate_trip(self, request, pk=None):
        trip = self.get_object()
        rating = request.data.get('rating')
        
        try:
            rating_value = float(rating)
            if not (1 <= rating_value <= 5):
                return Response(
                    {'error': 'Rating must be between 1 and 5'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except (TypeError, ValueError):
            return Response(
                {'error': 'Invalid rating value'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if trip.status != 'COMPLETED':
            return Response(
                {'error': 'Can only rate completed trips'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            trip.rating = rating_value
            trip.save()
            
            # Update driver's rating
            driver = trip.driver
            driver.rating = (
                (driver.rating * driver.total_trips + rating_value) /
                (driver.total_trips + 1)
            )
            driver.save()
            
            return Response({'message': 'Rating submitted successfully'})
        except Exception as e:
            logger.error(f"Rating submission error: {str(e)}")
            return Response(
                {'error': 'Failed to submit rating'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class WalletViewSet(BaseViewSet):
    permission_classes = [IsAuthenticated]
    queryset = Wallet.objects.all()
    serializer_class = WalletSerializer
    
    @action(detail=False, methods=['get'])
    def info(self, request):
        try:
            wallet = self.queryset.get(user=request.user)
            serializer = self.get_serializer(wallet)
            return Response(serializer.data)
        except Wallet.DoesNotExist:
            return Response(
                {'error': 'Wallet not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Wallet info error: {str(e)}")
            return Response(
                {'error': 'Failed to fetch wallet information'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['post'])
    def add_funds(self, request):
        try:
            amount = Decimal(request.data.get('amount', 0))
            if amount <= 0:
                return Response(
                    {'error': 'Amount must be positive'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if amount > 1000:
                return Response(
                    {'error': 'Cannot add more than $1,000 at once'},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            wallet = self.queryset.get(user=request.user)
            wallet.add_funds(amount)
            
            return Response({
                'message': 'Funds added successfully',
                'new_balance': str(wallet.current_balance),
                'transaction': PaymentSerializer(
                    wallet.payment_set.latest('created_at')
                ).data
            })
        except Wallet.DoesNotExist:
            return Response(
                {'error': 'Wallet not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid amount'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Add funds error: {str(e)}")
            return Response(
                {'error': 'Failed to add funds'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RouteViewSet(BaseViewSet):
    queryset = Route.objects.all()
    serializer_class = RouteSerializer

    @action(detail=False, methods=['post'])
    def optimize(self, request):
        stops = request.data.get('stops', [])
        if len(stops) < 2:
            return Response(
                {'error': 'At least 2 stops required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            optimized_route = Route.calculate_optimal_route(stops)
            return Response({'optimized_route': optimized_route})
        except Exception as e:
            logger.error(f"Route optimization error: {str(e)}")
            return Response(
                {'error': 'Failed to optimize route'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class GolfCartViewSet(BaseViewSet):
    queryset = GolfCart.objects.all()
    serializer_class = GolfCartSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status', 'type']

    @action(detail=True, methods=['post'])
    def update_location(self, request, pk=None):
        cart = self.get_object()
        location = request.data.get('location')
        
        if not location:
            return Response(
                {'error': 'Location data required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            cart.location = location
            cart.save()
            return Response({'message': 'Location updated successfully'})
        except Exception as e:
            logger.error(f"Location update error: {str(e)}")
            return Response(
                {'error': 'Failed to update location'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def schedule_maintenance(self, request, pk=None):
        cart = self.get_object()
        maintenance_date = request.data.get('maintenance_date')
        
        try:
            cart.maintenance_due = datetime.strptime(maintenance_date, '%Y-%m-%d')
            cart.save()
            return Response({'message': 'Maintenance scheduled successfully'})
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Maintenance scheduling error: {str(e)}")
            return Response(
                {'error': 'Failed to schedule maintenance'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PaymentViewSet(BaseViewSet):
    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['type', 'status']
    search_fields = ['payment_id']
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Users can only see their own payments
        if self.request.user.is_staff:
            return self.queryset
        return self.queryset.filter(wallet__user=self.request.user)

    def perform_create(self, serializer):
        # Validate wallet ownership
        wallet = serializer.validated_data['wallet']
        if wallet.user != self.request.user and not self.request.user.is_staff:
            raise PermissionDenied("You don't have permission to make payments for this wallet")
        serializer.save()

    @action(detail=False, methods=['get'])
    def summary(self, request):
        try:
            user_payments = self.get_queryset()
            total_added = user_payments.filter(
                type='ADD',
                status='COMPLETED'
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            total_spent = user_payments.filter(
                type='DEDUCT',
                status='COMPLETED'
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            recent_transactions = user_payments.order_by('-created_at')[:5]
            
            return Response({
                'total_added': str(total_added),
                'total_spent': str(total_spent),
                'balance': str(total_added - total_spent),
                'recent_transactions': PaymentSerializer(recent_transactions, many=True).data
            })
        except Exception as e:
            logger.error(f"Payment summary error: {str(e)}")
            return Response(
                {'error': 'Failed to fetch payment summary'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        try:
            today = timezone.now().date()
            start_of_month = today.replace(day=1)
            
            monthly_payments = self.get_queryset().filter(
                created_at__gte=start_of_month,
                status='COMPLETED'
            )
            
            by_type = monthly_payments.values('type').annotate(
                count=models.Count('id'),
                total=models.Sum('amount')
            )
            
            daily_totals = monthly_payments.annotate(
                date=models.functions.TruncDate('created_at')
            ).values('date').annotate(
                total=models.Sum('amount')
            ).order_by('date')
            
            return Response({
                'by_type': by_type,
                'daily_totals': daily_totals
            })
        except Exception as e:
            logger.error(f"Payment statistics error: {str(e)}")
            return Response(
                {'error': 'Failed to generate payment statistics'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def refund(self, request, pk=None):
        payment = self.get_object()
        
        if payment.type != 'DEDUCT' or payment.status != 'COMPLETED':
            return Response(
                {'error': 'Only completed deduction payments can be refunded'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            with transaction.atomic():
                # Create refund payment
                refund = Payment.objects.create(
                    wallet=payment.wallet,
                    amount=payment.amount,
                    type='ADD',
                    status='COMPLETED',
                    trip=payment.trip
                )
                
                # Update wallet balance
                payment.wallet.current_balance += payment.amount
                payment.wallet.save()
                
                return Response({
                    'message': 'Payment refunded successfully',
                    'refund': PaymentSerializer(refund).data
                })
        except Exception as e:
            logger.error(f"Payment refund error: {str(e)}")
            return Response(
                {'error': 'Failed to process refund'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def monthly_report(self, request):
        try:
            year = int(request.query_params.get('year', timezone.now().year))
            month = int(request.query_params.get('month', timezone.now().month))
            
            start_date = timezone.datetime(year, month, 1)
            if month == 12:
                end_date = timezone.datetime(year + 1, 1, 1)
            else:
                end_date = timezone.datetime(year, month + 1, 1)
            
            payments = self.get_queryset().filter(
                created_at__gte=start_date,
                created_at__lt=end_date,
                status='COMPLETED'
            )
            
            report_data = {
                'period': f"{year}-{month:02d}",
                'total_transactions': payments.count(),
                'total_amount': str(payments.aggregate(total=Sum('amount'))['total'] or 0),
                'by_type': payments.values('type').annotate(
                    count=models.Count('id'),
                    total=models.Sum('amount')
                ),
                'daily_summary': payments.annotate(
                    date=models.functions.TruncDate('created_at')
                ).values('date').annotate(
                    count=models.Count('id'),
                    total=models.Sum('amount')
                ).order_by('date')
            }
            
            return Response(report_data)
        except Exception as e:
            logger.error(f"Monthly report error: {str(e)}")
            return Response(
                {'error': 'Failed to generate monthly report'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
