from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework.validators import UniqueValidator

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(queryset=User.objects.all())]
    )
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password2 = serializers.CharField(write_only=True, required=True)
    name = serializers.CharField(required=True)
    mobile = serializers.CharField(required=True)
    id_card = serializers.FileField(required=False, allow_null=True)

    class Meta:
        model = User
        fields = ('email', 'password', 'password2', 'name', 'mobile', 'id_card')

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {"password": "Password fields didn't match."}
            )
        return attrs

    def create(self, validated_data):
        # Remove password2 and id_card from validated_data
        validated_data.pop('password2', None)
        id_card = validated_data.pop('id_card', None)
        
        # Create user with name and mobile
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['name'].split()[0],
            last_name=' '.join(validated_data['name'].split()[1:]) if len(validated_data['name'].split()) > 1 else '',
            phone_number=validated_data['mobile']
        )
        
        # Handle ID card file if provided
        if id_card:
            # Save the file with a unique name
            file_extension = id_card.name.split('.')[-1]
            file_name = f'id_card_{user.id}.{file_extension}'
            user.id_card.save(file_name, id_card, save=True)
            
        return user
