// BusTrackingSystem/static/js/dashboard.js

document.addEventListener('DOMContentLoaded', function() {
    const busStatusTableBody = document.querySelector('#bus-status-table-body');
    const metricsContent = document.getElementById('metrics-content');
    const alertsContainer = document.getElementById('active-alerts-container');

    // Fetches and displays the main dashboard metrics
    async function fetchDashboardMetrics() {
        if (!metricsContent) return;
        try {
            const busesResponse = await fetch('/api/buses/');
            const routesResponse = await fetch('/api/bus-lines/');
            if (!busesResponse.ok || !routesResponse.ok) return;

            const busesData = await busesResponse.json();
            const routesData = await routesResponse.json();

            const totalBuses = Array.isArray(busesData) ? busesData.length : (busesData.results ? busesData.results.length : 0);
            const totalRoutes = Array.isArray(routesData) ? routesData.length : (routesData.results ? routesData.results.length : 0);
            
            const metricsHtml = `
                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800/50">
                    <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Active Buses</p>
                    <p class="mt-1 text-3xl font-bold text-gray-900 dark:text-white">${totalBuses}</p>
                </div>
                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800/50">
                    <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Routes</p>
                    <p class="mt-1 text-3xl font-bold text-gray-900 dark:text-white">${totalRoutes}</p>
                </div>
                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800/50">
                    <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Drivers</p>
                    <p class="mt-1 text-3xl font-bold text-gray-900 dark:text-white">...</p>
                </div>
                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800/50">
                    <p class="text-sm font-medium text-gray-500 dark:text-gray-400">On Time</p>
                    <p class="mt-1 text-3xl font-bold text-gray-900 dark:text-white">95%</p>
                </div>
            `;
            metricsContent.innerHTML = metricsHtml;
        } catch (error) {
            console.error('Failed to fetch dashboard metrics:', error);
        }
    }

    // Fetches and displays the real-time bus status table
    async function fetchBusStatus() {
        if (!busStatusTableBody) return;
        try {
            const response = await fetch('/api/buses/');
            if (!response.ok) return;
            const data = await response.json();
            const buses = Array.isArray(data) ? data : data.results;
            
            if (buses && buses.length > 0) {
                busStatusTableBody.innerHTML = '';
                buses.forEach(bus => {
                    // FIX: Access the 'route_name' from the nested 'bus_line' object.
                    // The '?' checks if bus.bus_line exists before trying to access its properties.
                    const routeName = bus.bus_line ? bus.bus_line.route_name : 'N/A';
                    const row = `
                        <tr>
                            <td class="text-center px-6 py-4">${bus.bus_id}</td>
                            <td class="text-center px-6 py-4">${routeName}</td>
                            <td class="text-center px-6 py-4 text-green-500">On Time</td>
                            <td class="text-center px-6 py-4">Just now</td>
                        </tr>
                    `;
                    busStatusTableBody.innerHTML += row;
                });
            } else {
                busStatusTableBody.innerHTML = '<tr><td colspan="4" class="text-center py-4">No buses currently available.</td></tr>';
            }
        } catch (error) {
            console.error('Failed to fetch bus status:', error);
        }
    }

    // Fetches and displays active alerts
    async function fetchActiveAlerts() {
        if (!alertsContainer) return;
        try {
            const response = await fetch('/api/alerts/');
            if (!response.ok) return;
            const data = await response.json();
            const alerts = Array.isArray(data) ? data : data.results;

            alertsContainer.innerHTML = ''; 
            const activeAlerts = alerts.filter(alert => !alert.is_resolved);

            if (activeAlerts.length > 0) {
                activeAlerts.forEach(alert => {
                    // FIX: Access a specific property like 'license_plate' from the nested 'bus' object.
                    // This is more user-friendly than just the ID.
                    const busIdentifier = alert.bus ? alert.bus.license_plate : 'Unknown';
                    const alertHtml = `
                        <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4" role="alert">
                            <p class="font-bold">Bus ${busIdentifier} - [${alert.alert_type}]</p>
                            <p>${alert.message}</p>
                        </div>
                    `;
                    alertsContainer.innerHTML += alertHtml;
                });
            } else {
                alertsContainer.innerHTML = '<p class="text-gray-500 dark:text-gray-400">No active alerts.</p>';
            }
        } catch (error) {
            console.error('Failed to fetch alerts:', error);
        }
    }

    // Call all functions on page load
    fetchDashboardMetrics();
    fetchBusStatus();
    fetchActiveAlerts(); 
});