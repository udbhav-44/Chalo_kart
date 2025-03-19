from django.contrib import admin
from authentication.models import CustomUser
from django.contrib.auth.admin import UserAdmin

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'is_verified', 'is_phone_verified', 'phone_number', 'date_joined', 'is_active')
    list_filter = ('is_verified', 'is_phone_verified', 'is_active', 'date_joined')
    search_fields = ('email', 'username', 'phone_number')
    ordering = ('-date_joined',)
    
    fieldsets = (
        (None, {'fields': ('email', 'username', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'phone_number', 'id_card')}),
        ('Verification', {'fields': ('is_verified', 'is_phone_verified', 'otp', 'otp_created_at', 'reset_otp', 'reset_otp_created_at')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2'),
        }),
    ) 