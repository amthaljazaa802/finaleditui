import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')

# Initialize Django ASGI application early to ensure apps are loaded
django_asgi_app = get_asgi_application()

# Now import Channels components
from channels.routing import ProtocolTypeRouter, URLRouter
import bus_tracking.routing

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": URLRouter(
        bus_tracking.routing.websocket_urlpatterns
    ),
})
