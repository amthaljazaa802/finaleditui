# bus_tracking/urls.py

from . import views
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (BusViewSet, BusLineViewSet, BusStopViewSet,
                    LocationViewSet, BusLocationLogViewSet, AlertViewSet)
from .frontend_views import (admin_dashboard, manage_buses_view, manage_routes_view, 
                             manage_stops_view, manage_drivers_view, route_detail_view)
from django.views.generic import TemplateView

router = DefaultRouter()
# ... (router registrations remain the same) ...
router.register('locations', LocationViewSet)
router.register('bus-stops', BusStopViewSet)
router.register('bus-lines', BusLineViewSet)
router.register('buses', BusViewSet)
router.register('location-logs', BusLocationLogViewSet)
router.register('alerts', AlertViewSet)

urlpatterns = [
    path('accounts/', include('django.contrib.auth.urls')), 
    path('api/', include(router.urls)),
    path('api/initial-data/', views.initial_data_view, name='initial-data'),  # NEW: Combined endpoint
    path('', admin_dashboard, name='admin-dashboard'),
    path('buses/', manage_buses_view, name='manage-buses'),
    path('routes/', manage_routes_view, name='manage-routes'),
    path('stops/', manage_stops_view, name='manage-stops'),
    path('drivers/', manage_drivers_view, name='manage-drivers'),
    path('routes/<int:pk>/', route_detail_view, name='route-detail'),
    path('api/bus-line-stops/<int:pk>/', views.bus_line_stop_detail_view, name='bus-line-stop-detail'),
    path('websocket-test/', TemplateView.as_view(template_name='websocket_test.html'), name='websocket-test'),
]