from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.contrib.auth.hashers import make_password

class User(models.Model):
    user_name = models.CharField(max_length=100)
    email = models.EmailField(max_length=100, unique=True)
    password = models.CharField(max_length=128)
    phone = models.CharField(max_length=15, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    country = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.user_name} ({self.email})"

    def save(self, *args, **kwargs):
        if not self.password.startswith("pbkdf2_"):
            self.password = make_password(self.password)
        super().save(*args, **kwargs)

class Customer(User):
    is_student = models.BooleanField(default=False)
    govt_id = models.CharField(max_length=50, null=True, blank=True)
    emergency_contact = models.CharField(max_length=15, blank=True, null=True)
    preferred_payment_method = models.CharField(
        max_length=20,
        choices=[('WALLET', 'Wallet'), ('CARD', 'Card'), ('CASH', 'Cash')],
        default='WALLET'
    )

    def __str__(self):
        return f"Customer: {self.user_name}"

class Driver(User):
    driving_license = models.CharField(max_length=50, unique=True)
    rating = models.FloatField(
        default=5.0,
        validators=[MinValueValidator(1.0), MaxValueValidator(5.0)]
    )
    active_hours = models.IntegerField(default=0)
    total_earnings = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_trips = models.IntegerField(default=0)
    is_available = models.BooleanField(default=False)
    last_location_update = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Driver: {self.user_name} (Rating: {self.rating})"

class GolfCart(models.Model):
    gc_id = models.CharField(max_length=50, primary_key=True)
    type = models.CharField(
        max_length=10,
        choices=[('PRIVATE', 'Private'), ('SHUTTLE', 'Shuttle')],
        default='PRIVATE'
    )
    driver = models.OneToOneField(
        Driver,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='golf_cart'
    )
    capacity = models.IntegerField(default=4)
    registration_no = models.CharField(max_length=50, unique=True)
    maintenance_due = models.DateField(null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=[
            ('ACTIVE', 'Active'),
            ('INACTIVE', 'Inactive'),
            ('MAINTENANCE', 'Maintenance')
        ],
        default='INACTIVE'
    )
    location = models.JSONField(null=True, blank=True)
    last_maintenance = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"{self.type} Cart: {self.registration_no}"

class Route(models.Model):
    route_id = models.CharField(max_length=50, primary_key=True)
    start_coordinates = models.JSONField(default=dict)
    end_coordinates = models.JSONField(default=dict)
    stop_lists = models.JSONField(default=list)
    estimated_duration = models.IntegerField(default=0, help_text="Duration in minutes")
    distance = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text="Distance in kilometers")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Route {self.route_id}"

    @staticmethod
    def calculate_optimal_route(stops):
        return stops

class Trip(models.Model):
    trip_id = models.CharField(max_length=50, primary_key=True)
    customer = models.ForeignKey(Customer, on_delete=models.SET_NULL, null=True)
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True)
    golf_cart = models.ForeignKey(GolfCart, on_delete=models.SET_NULL, null=True)
    route = models.ForeignKey(Route, on_delete=models.SET_NULL, null=True)
    start_location = models.JSONField(default=dict)
    end_location = models.JSONField(default=dict)
    fare = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    duration = models.IntegerField(default=0, help_text="Duration in minutes")
    status = models.CharField(
        max_length=20,
        choices=[
            ('REQUESTED', 'Requested'),
            ('ACCEPTED', 'Accepted'),
            ('STARTED', 'Started'),
            ('COMPLETED', 'Completed'),
            ('CANCELLED', 'Cancelled')
        ],
        default='REQUESTED'
    )
    no_of_seats_booked = models.IntegerField(default=1)
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)
    rating = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Trip {self.trip_id}: {self.status}"

    def calculate_fare(self):
        base_fare = 5.00
        per_km_rate = 2.00
        per_minute_rate = 0.50
        
        distance_fare = float(self.route.distance) * per_km_rate if self.route else 0
        time_fare = self.duration * per_minute_rate if self.duration else 0
        
        return base_fare + distance_fare + time_fare

class Wallet(models.Model):
    wallet_id = models.CharField(max_length=50, primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    current_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Wallet: {self.user.user_name}"

    def add_funds(self, amount):
        if amount <= 0:
            raise ValueError("Amount must be positive")
        self.current_balance += amount
        self.save()
        
        Payment.objects.create(
            wallet=self,
            amount=amount,
            type='ADD',
            status='COMPLETED'
        )

    def deduct_funds(self, amount):
        if amount <= 0:
            raise ValueError("Amount must be positive")
        if self.current_balance < amount:
            raise ValueError("Insufficient balance")
        
        self.current_balance -= amount
        self.save()
        
        Payment.objects.create(
            wallet=self,
            amount=amount,
            type='DEDUCT',
            status='COMPLETED'
        )

class Payment(models.Model):
    payment_id = models.CharField(max_length=50, primary_key=True)
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE)
    trip = models.ForeignKey(Trip, on_delete=models.SET_NULL, null=True, blank=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    type = models.CharField(
        max_length=10,
        choices=[('ADD', 'Add'), ('DEDUCT', 'Deduct')],
        default='ADD'
    )
    status = models.CharField(
        max_length=20,
        choices=[
            ('PENDING', 'Pending'),
            ('COMPLETED', 'Completed'),
            ('FAILED', 'Failed')
        ],
        default='PENDING'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Payment {self.payment_id}: {self.type} {self.amount}"

    def save(self, *args, **kwargs):
        if not self.payment_id:
            self.payment_id = f"PAY_{timezone.now().strftime('%Y%m%d%H%M%S')}"
        super().save(*args, **kwargs)
