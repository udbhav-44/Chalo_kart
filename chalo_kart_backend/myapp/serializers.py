from rest_framework import serializers
from django.db.models import Avg
from django.utils import timezone
from .models import User, Customer, Driver, Trip, Wallet, Payment, GolfCart, Route

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'user_name', 'email', 'phone', 'address', 'city', 
                 'state', 'country', 'is_active']
        read_only_fields = ['id']
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True}
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        return value

    def create(self, validated_data):
        # Password hashing is now handled in the model's save method
        user = User.objects.create(**validated_data)
        # Create wallet for new user
        Wallet.objects.create(user=user)
        return user

class PaymentSerializer(serializers.ModelSerializer):
    wallet_balance = serializers.DecimalField(
        source='wallet.current_balance',
        max_digits=10,
        decimal_places=2,
        read_only=True
    )
    
    class Meta:
        model = Payment
        fields = ['payment_id', 'wallet', 'trip', 'amount', 'type', 
                 'status', 'created_at', 'wallet_balance']
        read_only_fields = ['payment_id', 'created_at', 'wallet_balance']

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive")
        return value

class WalletSerializer(serializers.ModelSerializer):
    recent_transactions = PaymentSerializer(many=True, read_only=True, source='payment_set')
    user_name = serializers.CharField(source='user.user_name', read_only=True)
    
    class Meta:
        model = Wallet
        fields = ['wallet_id', 'user', 'user_name', 'current_balance', 
                 'last_updated', 'recent_transactions']
        read_only_fields = ['wallet_id', 'last_updated']

class RouteSerializer(serializers.ModelSerializer):
    duration_display = serializers.SerializerMethodField()
    distance_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Route
        fields = ['route_id', 'start_coordinates', 'end_coordinates', 
                 'stop_lists', 'estimated_duration', 'distance', 
                 'duration_display', 'distance_display', 'created_at']
        read_only_fields = ['route_id', 'created_at']

    def get_duration_display(self, obj):
        hours = obj.estimated_duration // 60
        minutes = obj.estimated_duration % 60
        if hours > 0:
            return f"{hours}h {minutes}m"
        return f"{minutes}m"

    def get_distance_display(self, obj):
        return f"{float(obj.distance):.1f} km"

    def validate_stop_lists(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("Stop lists must be an array")
        if len(value) < 2:
            raise serializers.ValidationError("At least 2 stops are required")
        return value

class TripSerializer(serializers.ModelSerializer):
    route = RouteSerializer(read_only=True)
    payment = PaymentSerializer(read_only=True)
    driver_name = serializers.CharField(source='driver.user_name', read_only=True)
    customer_name = serializers.CharField(source='customer.user_name', read_only=True)
    fare_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Trip
        fields = ['trip_id', 'customer', 'customer_name', 'driver', 
                 'driver_name', 'golf_cart', 'route', 'start_location', 
                 'end_location', 'fare', 'fare_display', 'duration', 
                 'status', 'no_of_seats_booked', 'start_time', 
                 'end_time', 'rating', 'payment', 'created_at']
        read_only_fields = ['trip_id', 'fare', 'created_at']

    def get_fare_display(self, obj):
        return f"${float(obj.fare):.2f}"

    def validate_no_of_seats_booked(self, value):
        if value < 1:
            raise serializers.ValidationError("Must book at least 1 seat")
        if value > 4:
            raise serializers.ValidationError("Cannot book more than 4 seats")
        return value

class GolfCartSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.user_name', read_only=True)
    maintenance_status = serializers.SerializerMethodField()
    
    class Meta:
        model = GolfCart
        fields = ['gc_id', 'type', 'driver', 'driver_name', 'capacity', 
                 'registration_no', 'maintenance_due', 'status', 
                 'location', 'last_maintenance', 'maintenance_status']
        read_only_fields = ['gc_id']

    def get_maintenance_status(self, obj):
        if not obj.maintenance_due:
            return "No maintenance scheduled"
        days_until = (obj.maintenance_due - timezone.now().date()).days
        if days_until < 0:
            return "Maintenance overdue"
        if days_until == 0:
            return "Maintenance due today"
        return f"Maintenance due in {days_until} days"

class CustomerSerializer(serializers.ModelSerializer):
    trips = TripSerializer(many=True, read_only=True, source='trip_set')
    wallet = WalletSerializer(read_only=True)
    total_trips = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = ['id', 'user_name', 'email', 'phone', 'is_student', 
                 'govt_id', 'emergency_contact', 'preferred_payment_method',
                 'trips', 'wallet', 'total_trips']
        read_only_fields = ['id']
        extra_kwargs = {
            'password': {'write_only': True},
            'govt_id': {'write_only': True}
        }

    def get_total_trips(self, obj):
        return obj.trip_set.count()

class DriverSerializer(serializers.ModelSerializer):
    golf_cart = GolfCartSerializer(read_only=True)
    active_trips = serializers.SerializerMethodField()
    earnings_today = serializers.SerializerMethodField()
    rating_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Driver
        fields = ['id', 'user_name', 'email', 'phone', 'driving_license',
                 'rating', 'rating_display', 'active_hours', 'total_earnings', 
                 'total_trips', 'is_available', 'last_location_update',
                 'golf_cart', 'active_trips', 'earnings_today']
        read_only_fields = ['id', 'rating', 'total_earnings', 'total_trips']

    def get_active_trips(self, obj):
        active_trips = Trip.objects.filter(
            driver=obj,
            status__in=['ACCEPTED', 'STARTED']
        )
        return TripSerializer(active_trips, many=True).data

    def get_earnings_today(self, obj):
        today = timezone.now().date()
        trips_today = Trip.objects.filter(
            driver=obj,
            status='COMPLETED',
            end_time__date=today
        )
        return sum(trip.fare for trip in trips_today)

    def get_rating_display(self, obj):
        return f"{'★' * int(obj.rating)}{('☆' * (5 - int(obj.rating)))}"

    def validate_driving_license(self, value):
        if Driver.objects.filter(driving_license=value).exists():
            raise serializers.ValidationError("Driver license already registered")
        return value

class OTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15)
    otp = serializers.CharField(max_length=6)

    def validate(self, data):
        phone = data.get('phone')
        otp = data.get('otp')
        try:
            user = User.objects.get(phone=phone, otp=otp)
        except User.DoesNotExist:
            raise serializers.ValidationError('Invalid phone number or OTP')
        return data
