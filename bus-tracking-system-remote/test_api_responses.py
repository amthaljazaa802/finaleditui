#!/usr/bin/env python
"""Test API responses to see what the Flutter app receives"""

import os
import sys
import django
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token

# Get token
token = Token.objects.get(key='666af57b6bbae376bd45f2abf487d6ae04b6e0b7')

# Create API client
client = APIClient()
client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

print("=" * 60)
print("TESTING API RESPONSES")
print("=" * 60)

# Test /api/bus-stops/
print("\n1. Testing /api/bus-stops/")
print("-" * 60)
response = client.get('/api/bus-stops/')
print(f"Status Code: {response.status_code}")
print(f"Response:")
print(json.dumps(response.json(), indent=2))

# Test /api/buses/
print("\n2. Testing /api/buses/")
print("-" * 60)
response = client.get('/api/buses/')
print(f"Status Code: {response.status_code}")
print(f"Response:")
print(json.dumps(response.json(), indent=2, default=str))

# Test /api/bus-lines/
print("\n3. Testing /api/bus-lines/")
print("-" * 60)
response = client.get('/api/bus-lines/')
print(f"Status Code: {response.status_code}")
print(f"Response:")
print(json.dumps(response.json(), indent=2))

print("\n" + "=" * 60)
