import os
import django
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chalo_kart_backend.settings')
django.setup()

from django.conf import settings

def test_ssl_connection():
    print("Testing SSL Connection...")
    print(f"Host: {settings.EMAIL_HOST}")
    print(f"Port: {settings.EMAIL_PORT}")
    print(f"SSL: {settings.EMAIL_USE_SSL}")
    
    try:
        # Create SSL context
        context = ssl.create_default_context()
        
        # Create SMTP_SSL connection
        with smtplib.SMTP_SSL(settings.EMAIL_HOST, settings.EMAIL_PORT, context=context, timeout=300) as server:
            print("Connected to SMTP server")
            
            # Login
            server.login(settings.EMAIL_HOST_USER, settings.EMAIL_HOST_PASSWORD)
            print("Successfully logged in")
            
            # Create message
            msg = MIMEMultipart()
            msg['From'] = settings.EMAIL_HOST_USER
            msg['To'] = 'ssnishasis22@iitk.ac.in'
            msg['Subject'] = 'Test SSL Email Connection'
            
            body = 'This is a test email to verify SSL SMTP connection.'
            msg.attach(MIMEText(body, 'plain'))
            
            # Send email
            server.send_message(msg)
            print("Email sent successfully!")
            
    except Exception as e:
        print(f"Error: {str(e)}")
        print(f"Error type: {type(e)}")

if __name__ == "__main__":
    test_ssl_connection() 