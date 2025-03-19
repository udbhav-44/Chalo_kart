from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from myapp.views import (
    UserViewSet, CustomerViewSet, DriverViewSet,
    TripViewSet, WalletViewSet, PaymentViewSet,
    RouteViewSet, GolfCartViewSet, debug_password_reset, test_view
)
from django.http import HttpResponseRedirect
from django.contrib.auth import views as auth_views

# Create a router and register the viewsets with it
router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'customers', CustomerViewSet)
router.register(r'drivers', DriverViewSet)
router.register(r'trips', TripViewSet)
router.register(r'wallets', WalletViewSet)
router.register(r'payments', PaymentViewSet)
router.register(r'routes', RouteViewSet)
router.register(r'golfcarts', GolfCartViewSet)

# The API URLs are now determined automatically by the router.
urlpatterns = [
    # Admin URLs
    path('admin/', admin.site.urls),
    
    # Test URL
    path('test/', test_view, name='test_view'),
    
    # Debug URL for password reset
    path('debug-password-forget/<uidb64>/<token>/', debug_password_reset, name='debug_password_forget'),
    
    # Password forget URLs
    path('password-forget/', auth_views.PasswordResetView.as_view(
        template_name='registration/password_reset_form.html',
        email_template_name='registration/password_reset_email.html',
        success_url='/password-forget/done/'
    ), name='password_forget'),
    path('password-forget/done/', auth_views.PasswordResetDoneView.as_view(
        template_name='registration/password_reset_done.html'
    ), name='password_forget_done'),
    path('forget/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(
        template_name='registration/password_reset_confirm.html',
        success_url='/password-forget/complete/'
    ), name='password_forget_confirm'),
    path('password-forget/complete/', auth_views.PasswordResetCompleteView.as_view(
        template_name='registration/password_reset_complete.html'
    ), name='password_forget_complete'),
    
    # API URLs
    path('api/', include(router.urls)),
    path('api/users/send_otp/', UserViewSet.as_view({'post': 'send_otp'}), name='send_otp'),
    path('api/users/verify_otp/', UserViewSet.as_view({'post': 'verify_otp'}), name='verify_otp'),
    path('api/users/forgot_password_request/', UserViewSet.as_view({'post': 'forgot_password_request'}), name='forgot_password_request'),
    path('api/users/verify_forget_otp/', UserViewSet.as_view({'post': 'verify_forget_otp'}), name='verify_forget_otp'),
    
    # Redirect root URL to /api/
    path('', lambda request: HttpResponseRedirect('/api/')),
] 