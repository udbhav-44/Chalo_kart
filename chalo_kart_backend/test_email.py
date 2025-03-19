import os
import django
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chalo_kart_backend.settings')
django.setup()

from django.conf import settings

def test_smtp_connection():
    print("Testing SMTP Connection...")
    print(f"Host: {settings.EMAIL_HOST}")
    print(f"Port: {settings.EMAIL_PORT}")
    print(f"Username: {settings.EMAIL_HOST_USER}")
    print(f"TLS: {settings.EMAIL_USE_TLS}")
    
    try:
        # Create SMTP connection
        with smtplib.SMTP(settings.EMAIL_HOST, settings.EMAIL_PORT) as server:
            # Identify ourselves to the SMTP server
            server.ehlo()
            # Enable TLS encryption
            server.starttls()
            # Re-identify ourselves over TLS connection
            server.ehlo()
            # Login to the server
            server.login(settings.EMAIL_HOST_USER, settings.EMAIL_HOST_PASSWORD)
            
            # Create message
            msg = MIMEMultipart()
            msg['From'] = settings.EMAIL_HOST_USER
            msg['To'] = 'ssnishasis22@iitk.ac.in'
            msg['Subject'] = 'Test Email Connection'
            
            body = 'This is a test email to verify SMTP connection.'
            msg.attach(MIMEText(body, 'plain'))
            
            # Send email
            server.send_message(msg)
            print("Email sent successfully!")
            
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    test_smtp_connection() 