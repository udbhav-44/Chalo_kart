from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from .models import CustomUser
from unittest.mock import patch

class MobileVerificationTests(APITestCase):
    def setUp(self):
        self.user_data = {
            'email': 'test@example.com',
            'password': 'testpass123',
            'password2': 'testpass123',
            'mobile_number': '+1234567890'
        }
        self.user = CustomUser.objects.create_user(
            username='test@example.com',
            email='test@example.com',
            password='testpass123',
            mobile_number='+1234567890'
        )

    @patch('authentication.views.verify_firebase_token')
    def test_firebase_phone_auth(self, mock_verify_token):
        """Test Firebase phone authentication"""
        mock_verify_token.return_value = {
            'phone_number': '+1234567890'
        }
        
        url = reverse('firebase-phone-auth')
        data = {'id_token': 'fake_token'}
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', response.data)
        
        # Verify user is marked as mobile verified
        user = CustomUser.objects.get(mobile_number='+1234567890')
        self.assertTrue(user.is_mobile_verified)

    def test_resend_phone_verification(self):
        """Test resending phone verification"""
        url = reverse('resend-phone-verification')
        data = {'phone_number': '+1234567890'}
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('message', response.data)

    def test_invalid_phone_number_format(self):
        """Test invalid phone number handling"""
        url = reverse('resend-phone-verification')
        data = {'phone_number': 'invalid_number'}
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_nonexistent_user_phone_verification(self):
        """Test phone verification for non-existent user"""
        url = reverse('resend-phone-verification')
        data = {'phone_number': '+9999999999'}
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
