document.addEventListener('DOMContentLoaded', function() {
    // --- Element References ---
    const routeId = JSON.parse(document.getElementById('route-id').textContent);
    const routeInfoContainer = document.getElementById('route-info-container');
    const stopsOnRouteTableBody = document.getElementById('stops-on-route-table-body');
    const stopSelect = document.getElementById('stop-select');
    const addStopForm = document.getElementById('add-stop-to-route-form');
    const orderInput = document.getElementById('order-input');
    const addStopButton = document.getElementById('add-stop-button');

    // --- Helper function to get CSRF token for POST/DELETE requests ---
    function getCookie(name) {
        let cookieValue = null;
        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i].trim();
                if (cookie.substring(0, name.length + 1) === (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
    const csrftoken = getCookie('csrftoken');

    // --- Data Fetching Functions ---

    /**
     * Fetches and displays the main details of the current route.
     */
    async function fetchRouteDetails() {
        try {
            const response = await fetch(`/api/bus-lines/${routeId}/`);
            if (!response.ok) throw new Error('Failed to fetch route details');
            const route = await response.json();
            routeInfoContainer.innerHTML = `
                <h2 class="text-3xl font-bold text-gray-900 dark:text-white">Route: ${route.route_name}</h2>
                <p class="text-gray-500 dark:text-gray-400">${route.route_description || ''}</p>
            `;
        } catch (error) {
            console.error(error);
            routeInfoContainer.innerHTML = `<h2 class="text-3xl font-bold text-red-500">Could not load route details.</h2>`;
        }
    }

    /**
     * Fetches the list of stops for the current route and renders them in the table.
     */
    async function fetchStopsOnRoute() {
        try {
            const response = await fetch(`/api/bus-lines/${routeId}/stops_with_order/`);
            if (!response.ok) throw new Error('Failed to fetch stops for this route');
            const stops = await response.json();
            stopsOnRouteTableBody.innerHTML = ''; // Clear existing table rows
            if (stops && stops.length > 0) {
                // Sort stops by order number before displaying
                stops.sort((a, b) => a.order - b.order);
                stops.forEach(item => {
                    const row = `
                        <tr class="border-b bg-white dark:border-gray-700 dark:bg-gray-800">
                            <td class="whitespace-nowrap px-6 py-4 font-medium text-gray-900 dark:text-white">${item.order}</td>
                            <td class="px-6 py-4 text-gray-700 dark:text-gray-300">${item.bus_stop.stop_name}</td>
                            <td class="px-6 py-4">
                                <button class="font-medium text-red-600 hover:underline dark:text-red-500" data-buslinestop-id="${item.id}">Remove</button>
                            </td>
                        </tr>`;
                    stopsOnRouteTableBody.innerHTML += row;
                });
            } else {
                stopsOnRouteTableBody.innerHTML = `
                    <tr class="border-b bg-white dark:border-gray-700 dark:bg-gray-800">
                        <td colspan="3" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">
                            This route has no stops assigned yet.
                        </td>
                    </tr>`;
            }
        } catch (error) {
            console.error(error);
        }
    }

    /**
     * Fetches all available bus stops and populates the dropdown menu.
     */
    async function populateStopSelect() {
        try {
            const response = await fetch('/api/bus-stops/');
            if (!response.ok) throw new Error('Failed to fetch all stops');
            const allStops = await response.json();
            stopSelect.innerHTML = '<option value="">-- Select a stop --</option>';
            if (allStops) {
                const stops = Array.isArray(allStops) ? allStops : allStops.results;
                stops.forEach(stop => {
                    const option = `<option value="${stop.stop_id}">${stop.stop_name}</option>`;
                    stopSelect.innerHTML += option;
                });
            }
        } catch (error) {
            console.error(error);
        }
    }

    // --- Action Handler Functions ---

    /**
     * Handles the "Add Stop" button click to add a new stop to the route.
     */
    async function handleAddStop(event) {
        event.preventDefault(); // Prevent default form submission behavior

        const selectedStopId = stopSelect.value;
        const orderValue = orderInput.value;

        if (!selectedStopId || !orderValue) {
            alert('Please select a stop and enter an order number.');
            return;
        }

        try {
            const response = await fetch(`/api/bus-lines/${routeId}/add-stop/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrftoken,
                },
                body: JSON.stringify({
                    stop_id: selectedStopId,
                    order: parseInt(orderValue, 10),
                }),
            });
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || 'Failed to add stop to route');
            }
            await response.json();
            fetchStopsOnRoute(); // Refresh the table
            addStopForm.reset(); // Clear the form
        } catch (error) {
            console.error('Error adding stop:', error);
            alert(`Error: ${error.message}`);
        }
    }

    /**
     * Handles clicks on the "Remove" buttons using event delegation.
     */
    async function handleRemoveClick(event) {
        // Check if a remove button (an element with the data-buslinestop-id attribute) was clicked
        if (!event.target.matches('[data-buslinestop-id]')) {
            return;
        }

        const busLineStopId = event.target.dataset.buslinestopId;

        if (confirm('Are you sure you want to remove this stop from the route?')) {
            try {
                const response = await fetch(`/api/bus-line-stops/${busLineStopId}/`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRFToken': csrftoken,
                    },
                });

                if (response.status !== 204) { // 204 No Content is the expected success status for DELETE
                    throw new Error('Failed to remove stop. Server responded unexpectedly.');
                }

                fetchStopsOnRoute(); // If successful, refresh the table of stops

            } catch (error) {
                console.error('Error removing stop:', error);
                alert('An error occurred while trying to remove the stop.');
            }
        }
    }

    // --- Attach Event Listeners ---

    // Listen for clicks on the "Add Stop" button
    if (addStopButton) {
        addStopButton.addEventListener('click', handleAddStop);
    } else {
        console.error("Critical Error: Could not find the button with id 'add-stop-button'.");
    }

    // Listen for clicks within the table body to handle any "Remove" button clicks
    stopsOnRouteTableBody.addEventListener('click', handleRemoveClick);

    // --- Initial Page Load ---
    fetchRouteDetails();
    fetchStopsOnRoute();
    populateStopSelect();
});