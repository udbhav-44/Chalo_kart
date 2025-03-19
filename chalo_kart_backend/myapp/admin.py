from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import Group
from django.utils.translation import gettext_lazy as _
from .models import User, Customer, Driver, GolfCart, Route, Wallet, Payment, Trip

# First, unregister the default User and Group admin
admin.site.unregister(Group)

class UserAdmin(BaseUserAdmin):
    list_display = ('user_name', 'email', 'phone', 'is_active', 'is_staff', 'get_role')
    list_filter = ('is_active', 'is_staff')
    search_fields = ('user_name', 'email', 'phone')
    ordering = ('user_name',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('user_name', 'phone', 'address', 'city', 'state', 'country')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'user_name', 'password1', 'password2'),
        }),
    )

    def get_role(self, obj):
        if obj.is_superuser:
            return 'Administrator'
        if hasattr(obj, 'driver'):
            return 'Driver'
        if hasattr(obj, 'customer'):
            return 'Rider'
        return 'Regular User'
    get_role.short_description = 'Role'

# Drivers
@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ('user_name', 'email', 'phone', 'driving_license', 'rating', 'is_available', 'total_trips')
    list_filter = ('is_available', 'is_active')
    search_fields = ('user_name', 'email', 'phone', 'driving_license')
    fieldsets = (
        ('User Information', {'fields': ('user_name', 'email', 'phone', 'password')}),
        ('Personal Information', {'fields': ('address', 'city', 'state', 'country')}),
        ('Driver Details', {
            'fields': (
                'driving_license', 'rating', 'active_hours', 
                'total_earnings', 'total_trips', 'is_available'
            )
        }),
        ('Status', {'fields': ('is_active',)}),
    )

# Customers (Riders)
@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('user_name', 'email', 'phone', 'is_student', 'preferred_payment_method')
    list_filter = ('is_student', 'preferred_payment_method', 'is_active')
    search_fields = ('user_name', 'email', 'phone')
    fieldsets = (
        ('User Information', {'fields': ('user_name', 'email', 'phone', 'password')}),
        ('Personal Information', {'fields': ('address', 'city', 'state', 'country')}),
        ('Customer Details', {'fields': ('is_student', 'govt_id', 'emergency_contact', 'preferred_payment_method')}),
        ('Status', {'fields': ('is_active',)}),
    )

# Register the models
admin.site.register(User, UserAdmin)

# Customize admin site
admin.site.site_header = "Chalo Kart Administration"
admin.site.site_title = "Chalo Kart Admin Portal"
admin.site.index_title = "Welcome to Chalo Kart Admin Portal"

# Update the names in admin
UserAdmin.verbose_name = "Administrators"
UserAdmin.verbose_name_plural = "Administrators"
CustomerAdmin.verbose_name = "Riders"
CustomerAdmin.verbose_name_plural = "Riders"
DriverAdmin.verbose_name = "Drivers"
DriverAdmin.verbose_name_plural = "Drivers"

@admin.register(GolfCart)
class GolfCartAdmin(admin.ModelAdmin):
    list_display = ('gc_id', 'type', 'driver', 'registration_no', 'status', 'capacity')
    list_filter = ('type', 'status')
    search_fields = ('gc_id', 'registration_no', 'driver__user_name')

@admin.register(Route)
class RouteAdmin(admin.ModelAdmin):
    list_display = ('route_id', 'estimated_duration', 'distance', 'created_at')
    search_fields = ('route_id',)

@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ('trip_id', 'customer', 'driver', 'status', 'fare', 'created_at')
    list_filter = ('status',)
    search_fields = ('trip_id', 'customer__email', 'driver__email')

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('wallet_id', 'user', 'current_balance', 'last_updated')
    search_fields = ('wallet_id', 'user__user_name', 'user__email')

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('payment_id', 'wallet', 'amount', 'type', 'status', 'created_at')
    list_filter = ('type', 'status')
    search_fields = ('payment_id', 'wallet__wallet_id')
