import firebase_admin
from firebase_admin import credentials, auth
import uuid
import time

# Initialize Firebase Admin SDK
cred = credentials.Certificate('/Users/snehasissatapathy/Desktop/CS253/Chalo_kart/chalo_kart_backend/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

# Simulate sending OTP
def send_otp_simulation(phone_number):
    # Generate a random OTP (in a real system, you'd send this via SMS)
    otp = '123456'  # Replace with actual OTP generation logic
    print(f"Simulated OTP sent to {phone_number}: {otp}")
    return otp

# Simulate OTP verification and user creation/authentication
def verify_otp_and_authenticate(phone_number, provided_otp, expected_otp='123456'):
    # Verify the OTP
    if provided_otp != expected_otp:
        print("Invalid OTP")
        return None
    
    # Check if user exists, create if not
    try:
        user = auth.get_user_by_phone_number(phone_number)
        print(f"Existing user found with phone: {phone_number}")
    except auth.UserNotFoundError:
        # Create a new user with the phone number
        user = auth.create_user(
            phone_number=phone_number,
            uid=f"phone-{uuid.uuid4()}"  # Generate unique ID
        )
        print(f"New user created with phone: {phone_number}, UID: {user.uid}")
    
    # Create a custom token for this user
    custom_token = auth.create_custom_token(user.uid).decode('utf-8')
    print(f"Custom token created for user {user.uid}")
    
    # In a real app, this token would be sent to the client
    # and exchanged for an ID token
    
    return {
        "user_id": user.uid,
        "custom_token": custom_token,
        "message": "Authentication successful"
    }

# TESTING FUNCTIONS

# Test the OTP flow
def test_phone_auth_flow():
    phone_number = "+919599049577"
    
    # Step 1: Send OTP
    expected_otp = send_otp_simulation(phone_number)
    print("\n--- OTP Sent ---\n")
    
    # Step 2: Verify OTP (successful case)
    auth_result = verify_otp_and_authenticate(phone_number, expected_otp)
    if auth_result:
        print(f"\n--- Authentication Successful ---")
        print(f"User ID: {auth_result['user_id']}")
        print(f"Custom Token: {auth_result['custom_token'][:20]}...")
    
    # Step 3: Test invalid OTP
    print("\n--- Testing Invalid OTP ---")
    invalid_result = verify_otp_and_authenticate(phone_number, "wrong-otp")
    if invalid_result is None:
        print("Invalid OTP correctly rejected")

# Run the test
test_phone_auth_flow()