document.addEventListener('DOMContentLoaded', function() {
    const routesTableBody = document.querySelector('#routes-table-body');
    const addRouteToggleBtn = document.getElementById('add-route-toggle-btn');
    const deleteModal = document.getElementById('delete-modal');
    const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
    const cancelDeleteBtn = document.getElementById('cancel-delete-btn');

    // --- STATE MANAGEMENT ---
    let routeToDeleteId = null;
    let editingRouteId = null;
    let isAddingNewRoute = false;

    // --- HELPER FUNCTIONS ---
    // Using the more reliable getCookie function for CSRF
    function getCsrfToken() {
        let cookieValue = null;
        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i].trim();
                if (cookie.substring(0, 'csrftoken'.length + 1) === ('csrftoken' + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring('csrftoken'.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }

    // --- MASTER RENDERING FUNCTION ---
    async function fetchRoutes() {
        try {
            const response = await fetch('/api/bus-lines/');
            if (!response.ok) throw new Error('Failed to fetch routes');
            const data = await response.json();
            const routes = Array.isArray(data) ? data : data.results;

            routesTableBody.innerHTML = ''; // Always start with a clean table

            // Render the "Add New Route" form if in the adding state
            if (isAddingNewRoute) {
                routesTableBody.innerHTML += `
                    <tr id="add-route-row">
                        <td class="whitespace-nowrap px-6 py-4"><input type="text" name="route_name" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" placeholder="New Route Name" required></td>
                        <td class="whitespace-nowrap px-6 py-4"><input type="text" name="route_description" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" placeholder="Description"></td>
                        <td class="whitespace-nowrap px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-4">
                                <button class="save-new-btn text-green-500 hover:text-green-400"><span class="material-symbols-outlined">done</span></button>
                                <button class="cancel-new-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined">close</span></button>
                            </div>
                        </td>
                    </tr>
                `;
            }

            // Render the list of routes
            if (routes && routes.length > 0) {
                routes.forEach(route => {
                    // FIX: Changed all instances of 'bus_line_id' to 'route_id' to match the API
                    if (route.route_id === editingRouteId) {
                        // Render the row in edit mode
                        routesTableBody.innerHTML += `
                            <tr data-route-id="${route.route_id}" class="bg-blue-50 dark:bg-blue-900/50">
                                <td class="route-name-cell whitespace-nowrap px-6 py-4"><input type="text" class="bg-white dark:bg-gray-700 rounded w-full p-1" value="${route.route_name}"></td>
                                <td class="route-description-cell whitespace-nowrap px-6 py-4"><input type="text" class="bg-white dark:bg-gray-700 rounded w-full p-1" value="${route.route_description || ''}"></td>
                                <td class="actions-cell whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                                    <div class="flex items-center justify-end gap-4">
                                        <button class="save-edit-btn text-green-500 hover:text-green-400"><span class="material-symbols-outlined text-base">done</span></button>
                                        <button class="cancel-edit-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined text-base">close</span></button>
                                    </div>
                                </td>
                            </tr>
                        `;
                    } else {
                        // Render the row in normal view mode
                        routesTableBody.innerHTML += `
                            <tr data-route-id="${route.route_id}" class="hover:bg-gray-50 dark:hover:bg-background-dark">
                                <td class="route-name-cell whitespace-nowrap px-6 py-4 text-sm font-medium">
                                    <a href="/routes/${route.route_id}/" class="text-primary hover:underline">${route.route_name}</a>
                                </td>
                                <td class="route-description-cell whitespace-nowrap px-6 py-4 text-sm text-gray-500 dark:text-gray-400">${route.route_description || 'N/A'}</td>
                                <td class="actions-cell whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                                    <div class="flex items-center justify-end gap-4">
                                        <button class="edit-btn text-primary hover:text-primary/80"><span class="material-symbols-outlined text-base">edit</span></button>
                                        <button class="delete-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined text-base">delete</span></button>
                                    </div>
                                </td>
                            </tr>
                        `;
                    }
                });
            } else if (!isAddingNewRoute) {
                routesTableBody.innerHTML = '<tr><td colspan="3" class="text-center p-4">No routes available.</td></tr>';
            }
        } catch (error) {
            console.error('Failed to fetch routes:', error);
        }
    }

    // --- API CALL FUNCTIONS ---
    async function handleAddSubmit() {
        const routeName = document.querySelector('#add-route-row input[name=route_name]').value;
        const routeDescription = document.querySelector('#add-route-row input[name=route_description]').value;
        try {
            const response = await fetch('/api/bus-lines/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify({ route_name: routeName, route_description: routeDescription })
            });
            if (!response.ok) throw new Error('Failed to add route');
            isAddingNewRoute = false;
            fetchRoutes();
        } catch (error) {
            console.error('Error adding route:', error);
        }
    }

    async function saveEditedRoute(row, routeId) {
        const newName = row.querySelector('.route-name-cell input').value;
        const newDesc = row.querySelector('.route-description-cell input').value;
        try {
            const response = await fetch(`/api/bus-lines/${routeId}/`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify({ route_name: newName, route_description: newDesc })
            });
            if (!response.ok) throw new Error('Failed to save changes');
            editingRouteId = null;
            fetchRoutes();
        } catch (error) {
            console.error('Error saving route:', error);
        }
    }

    async function deleteRoute(routeId) {
        try {
            const response = await fetch(`/api/bus-lines/${routeId}/`, {
                method: 'DELETE',
                headers: { 'X-CSRFToken': getCsrfToken() }
            });
            if (!response.ok) throw new Error('Failed to delete route');
            fetchRoutes();
        } catch (error) {
            console.error('Error deleting route:', error);
        }
    }

    // --- MAIN EVENT LISTENERS ---
    addRouteToggleBtn.addEventListener('click', () => {
        isAddingNewRoute = !isAddingNewRoute;
        editingRouteId = null;
        fetchRoutes();
    });
    
    routesTableBody.addEventListener('click', (event) => {
        const target = event.target;
        const row = target.closest('tr');
        if (!row) return;

        // Add form actions
        if (target.closest('.save-new-btn')) handleAddSubmit();
        if (target.closest('.cancel-new-btn')) {
            isAddingNewRoute = false;
            fetchRoutes();
        }

        const routeId = row.getAttribute('data-route-id');
        if (!routeId) return;

        // Edit/Delete actions
        if (target.closest('.edit-btn')) {
            editingRouteId = parseInt(routeId, 10);
            isAddingNewRoute = false;
            fetchRoutes();
        }
        if (target.closest('.delete-btn')) {
            routeToDeleteId = routeId;
            deleteModal.classList.remove('hidden');
        }
        if (target.closest('.save-edit-btn')) {
            saveEditedRoute(row, routeId);
        }
        if (target.closest('.cancel-edit-btn')) {
            editingRouteId = null;
            fetchRoutes();
        }
    });

    // Modal listeners
    confirmDeleteBtn.addEventListener('click', () => {
        if (routeToDeleteId) {
            deleteRoute(routeToDeleteId);
            deleteModal.classList.add('hidden');
            routeToDeleteId = null;
        }
    });

    cancelDeleteBtn.addEventListener('click', () => {
        deleteModal.classList.add('hidden');
        routeToDeleteId = null;
    });

    // Initial load
    fetchRoutes();
});