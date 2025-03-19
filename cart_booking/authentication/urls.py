from django.urls import path
from .views import (
    RegisterView, LoginView, FirebasePhoneAuthView,
    VerifyEmailView, ResendVerificationView,
    RequestPasswordResetView, ResetPasswordConfirmView,
    SendEmailVerificationView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('verify-firebase-token/', FirebasePhoneAuthView.as_view(), name='verify-firebase-token'),
    path('verify-email/', VerifyEmailView.as_view(), name='verify-email'),
    path('resend-verification/', ResendVerificationView.as_view(), name='resend-verification'),
    path('request-password-reset/', RequestPasswordResetView.as_view(), name='request-password-reset'),
    path('reset-password/', ResetPasswordConfirmView.as_view(), name='reset-password'),
    path('send-email-verification/', SendEmailVerificationView.as_view(), name='send-email-verification'),
]