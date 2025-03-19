import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chalo_kart_backend.settings')
django.setup()

from django.core.mail import send_mail
from django.conf import settings

send_mail(
    'Test Email',
    'This is a test email from Django.',
    settings.EMAIL_HOST_USER,
    ['ssnishasis22@iitk.ac.in'],  # Replace with your actual email
    fail_silently=False,
)