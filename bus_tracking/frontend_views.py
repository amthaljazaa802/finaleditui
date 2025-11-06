# bus_tracking/frontend_views.py

from django.shortcuts import render
from django.contrib.auth.decorators import login_required

@login_required
def admin_dashboard(request):
    return render(request, 'dashboard_content.html', {'user': request.user})

@login_required
def manage_buses_view(request):
    return render(request, 'manage_buses.html', {'user': request.user})

@login_required
def manage_routes_view(request):
    return render(request, 'manage_routes.html', {'user': request.user})

@login_required
def manage_stops_view(request):
    return render(request, 'manage_stops.html', {'user': request.user})

@login_required
def manage_drivers_view(request):
    return render(request, 'manage_drivers.html', {'user': request.user})

# -- التابع الجديد لصفحة تفاصيل المسار --
@login_required
def route_detail_view(request, pk):
    # نمرر الـ pk (الرقم التعريفي للمسار) إلى القالب
    return render(request, 'route_detail.html', {'route_id': pk})