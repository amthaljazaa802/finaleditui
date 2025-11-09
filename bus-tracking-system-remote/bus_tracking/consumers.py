# bus_tracking/consumers.py

import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User

logger = logging.getLogger(__name__)


class BusLocationConsumer(AsyncWebsocketConsumer):
    """
    Async WebSocket consumer for real-time bus location updates.
    
    Features:
    - Token-based authentication (User app مستخدم النظام)
    - Secure WebSocket (wss://) support
    - Real-time bus location broadcasting
    - Group-based message routing (bus_locations group)
    
    Connection URL: wss://api.example.com/ws/bus-locations/
    Header: Authorization: Token <user-token>
    """

    async def connect(self):
        """
        Handle WebSocket connection with authentication.
        Client يجب يرسل token في الـ headers أو URL.
        """
        try:
            # الحصول على token من الـ query params أو headers
            token = self.scope.get('query_string', b'').decode().split('token=')[-1] if 'token=' in self.scope.get('query_string', b'').decode() else None
            
            if not token:
                # محاولة الحصول من headers
                headers = dict(self.scope.get('headers', []))
                auth_header = headers.get(b'authorization', b'').decode()
                if auth_header.startswith('Bearer '):
                    token = auth_header.split(' ')[1]
                elif auth_header.startswith('Token '):
                    token = auth_header.split(' ')[1]
            
            # التحقق من token (optional in development)
            if token and await self.authenticate_token(token):
                # إضافة المستخدم للنطاق
                self.user = await self.get_user_from_token(token)
                logger.info(f"WebSocket connected for user: {self.user.username}")
            else:
                # Allow anonymous connections in development
                self.user = None
                logger.warning(f"WebSocket connection without authentication (development mode)")
            
            # قبول الاتصال
            await self.accept()
            
            # الانضمام إلى مجموعة bus_locations
            await self.channel_layer.group_add('bus_locations', self.channel_name)
            logger.info(f"Client joined bus_locations group")
            
        except Exception as e:
            logger.error(f"Connection error: {str(e)}")
            await self.close(code=4000)  # Custom close code: Internal error

    async def disconnect(self, close_code):
        """
        Handle WebSocket disconnection and cleanup.
        """
        try:
            # مغادرة المجموعة
            await self.channel_layer.group_discard('bus_locations', self.channel_name)
            logger.info(f"User {getattr(self, 'user', 'Unknown')} disconnected (code: {close_code})")
        except Exception as e:
            logger.error(f"Disconnect error: {str(e)}")

    async def receive(self, text_data):
        """
        Handle incoming WebSocket messages from client.
        يمكن استخدامه للمستقبل (مثلاً: subscribe to specific bus)
        """
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'subscribe_bus':
                # Subscribe to specific bus updates
                bus_id = data.get('bus_id')
                await self.channel_layer.group_add(f'bus_{bus_id}', self.channel_name)
                await self.send(text_data=json.dumps({
                    'type': 'subscription_confirmed',
                    'bus_id': bus_id
                }))
                logger.info(f"User {self.user.username} subscribed to bus {bus_id}")
            
            elif message_type == 'heartbeat':
                # Simple heartbeat to keep connection alive
                await self.send(text_data=json.dumps({'type': 'heartbeat_ack'}))
            
            else:
                await self.send(text_data=json.dumps({
                    'type': 'error',
                    'message': f'Unknown message type: {message_type}'
                }))
        except json.JSONDecodeError:
            logger.warning("Invalid JSON received from WebSocket")
            await self.send(text_data=json.dumps({'type': 'error', 'message': 'Invalid JSON'}))
        except Exception as e:
            logger.error(f"Receive error: {str(e)}")

    async def bus_location_update(self, event):
        """
        Receive message from group and send to WebSocket client.
        يتم استدعاؤها عند بث تحديث موقع الحافلة.
        """
        try:
            logger.info(f"[Consumer] Sending bus location update to client: {event.get('data', {})}")
            # إرسال البيانات إلى WebSocket
            await self.send(text_data=json.dumps({
                'type': 'bus_location_update',
                'data': event.get('data', {})
            }))
            logger.info(f"[Consumer] Successfully sent update to client")
        except Exception as e:
            logger.error(f"Error sending location update: {str(e)}")

    # =====================================================================
    # Helper Methods
    # =====================================================================

    @database_sync_to_async
    def authenticate_token(self, token: str) -> bool:
        """
        التحقق من صحة الـ token (Token-based authentication).
        """
        try:
            Token.objects.get(key=token)
            return True
        except Token.DoesNotExist:
            return False

    @database_sync_to_async
    def get_user_from_token(self, token: str) -> User:
        """
        الحصول على المستخدم من الـ token.
        """
        try:
            token_obj = Token.objects.get(key=token)
            return token_obj.user
        except Token.DoesNotExist:
            return None