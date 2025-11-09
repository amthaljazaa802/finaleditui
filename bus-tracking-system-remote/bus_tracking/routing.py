# bus_tracking/routing.py
"""
WebSocket routing configuration for Django Channels.

Secure WebSocket URLs (wss://) are handled here.
All connections require token-based authentication.
"""

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # User app WebSocket endpoint
    # URL: wss://api.example.com/ws/bus-locations/?token=<token>
    # Alternative: Authorization header: Bearer <token>
    # 
    # الاتصال الآمن للمستخدمين (User app) - wss://
    # كل اتصال يتطلب token صحيح
    re_path(r'ws/bus-locations/?$', consumers.BusLocationConsumer.as_asgi()),
]