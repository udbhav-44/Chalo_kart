"""
URL configuration for chalo_kart project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from myapp.views import (
    UserViewSet, CustomerViewSet, DriverViewSet,
    TripViewSet, WalletViewSet, PaymentViewSet,
    RouteViewSet, GolfCartViewSet
)

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
    path('api/', include(router.urls)),
]
