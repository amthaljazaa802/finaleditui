document.addEventListener('DOMContentLoaded', function() {
    const stopsTableBody = document.querySelector('#stops-table-body');
    const addStopToggleBtn = document.getElementById('add-stop-toggle-btn');
    const deleteModal = document.getElementById('delete-modal');
    const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
    const cancelDeleteBtn = document.getElementById('cancel-delete-btn');
    let stopToDeleteId = null;

    function getCsrfToken() {
        return document.querySelector('input[name=csrfmiddlewaretoken]').value;
    }

    async function fetchStops() {
        try {
            const response = await fetch('/api/bus-stops/');
            if (!response.ok) throw new Error('Failed to fetch stops');
            const data = await response.json();
            const stops = Array.isArray(data) ? data : data.results;

            stopsTableBody.innerHTML = ''; 

            if (stops && stops.length > 0) {
                stops.forEach(stop => {
                    const row = document.createElement('tr');
                    row.className = "hover:bg-gray-50 dark:hover:bg-background-dark";
                    row.setAttribute('data-stop-id', stop.stop_id);
                    row.innerHTML = `
                        <td class="stop-name-cell whitespace-nowrap px-6 py-4 text-sm font-medium">${stop.stop_name}</td>
                        <td class="latitude-cell whitespace-nowrap px-6 py-4 text-sm">${stop.location.latitude}</td>
                        <td class="longitude-cell whitespace-nowrap px-6 py-4 text-sm">${stop.location.longitude}</td>
                        <td class="actions-cell whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                            <div class="flex items-center justify-end gap-4">
                                <button class="edit-btn text-primary hover:text-primary/80"><span class="material-symbols-outlined text-base">edit</span></button>
                                <button class="delete-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined text-base">delete</span></button>
                            </div>
                        </td>
                    `;
                    stopsTableBody.appendChild(row);
                });
            } else {
                stopsTableBody.innerHTML = '<tr><td colspan="4" class="text-center p-4">No stops available. Click "Add New Stop" to begin.</td></tr>';
            }
        } catch (error) {
            console.error('Failed to fetch stops:', error);
        }
    }

    function showAddRow() {
        if (document.getElementById('add-stop-row')) return;
        const row = document.createElement('tr');
        row.id = 'add-stop-row';
        row.innerHTML = `
            <td class="whitespace-nowrap px-6 py-4"><input type="text" name="stop_name" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" placeholder="Stop Name" required></td>
            <td class="whitespace-nowrap px-6 py-4"><input type="text" name="latitude" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" placeholder="Latitude" required></td>
            <td class="whitespace-nowrap px-6 py-4"><input type="text" name="longitude" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" placeholder="Longitude" required></td>
            <td class="whitespace-nowrap px-6 py-4 text-right">
                <div class="flex items-center justify-end gap-4">
                    <button class="save-new-btn text-green-500 hover:text-green-400"><span class="material-symbols-outlined">done</span></button>
                    <button class="cancel-new-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined">close</span></button>
                </div>
            </td>
        `;
        stopsTableBody.prepend(row);
    }
    
    async function handleAddSubmit() {
        const stopName = document.querySelector('#add-stop-row input[name=stop_name]').value;
        const latitude = document.querySelector('#add-stop-row input[name=latitude]').value;
        const longitude = document.querySelector('#add-stop-row input[name=longitude]').value;
        try {
            const response = await fetch('/api/bus-stops/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify({ stop_name: stopName, latitude, longitude })
            });
            if (!response.ok) throw new Error('Failed to add stop');
            fetchStops();
        } catch (error) {
            console.error('Error adding stop:', error);
        }
    }

    function handleEditMode(row) {
        const nameCell = row.querySelector('.stop-name-cell');
        const latCell = row.querySelector('.latitude-cell');
        const lonCell = row.querySelector('.longitude-cell');
        const actionsCell = row.querySelector('.actions-cell .flex');
        
        const currentName = nameCell.textContent;
        const currentLat = latCell.textContent;
        const currentLon = lonCell.textContent;

        nameCell.innerHTML = `<input type="text" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" value="${currentName}">`;
        latCell.innerHTML = `<input type="text" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" value="${currentLat}">`;
        lonCell.innerHTML = `<input type="text" class="bg-gray-100 dark:bg-gray-700 rounded w-full p-1" value="${currentLon}">`;
        
        actionsCell.innerHTML = `
            <button class="save-edit-btn text-green-500 hover:text-green-400"><span class="material-symbols-outlined">done</span></button>
            <button class="cancel-edit-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined">close</span></button>
        `;
    }

    async function saveEditedStop(row, stopId) {
        const newName = row.querySelector('.stop-name-cell input').value;
        const newLat = row.querySelector('.latitude-cell input').value;
        const newLon = row.querySelector('.longitude-cell input').value;

        try {
            const response = await fetch(`/api/bus-stops/${stopId}/`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify({ stop_name: newName, latitude: newLat, longitude: newLon })
            });
            if (!response.ok) throw new Error('Failed to save changes');
            fetchStops();
        } catch (error) {
            console.error('Error saving stop:', error);
        }
    }

    async function deleteStop(stopId) {
        try {
            const response = await fetch(`/api/bus-stops/${stopId}/`, {
                method: 'DELETE',
                headers: { 'X-CSRFToken': getCsrfToken() }
            });
            if (!response.ok) throw new Error('Failed to delete stop');
            fetchStops();
        } catch (error) {
            console.error('Error deleting stop:', error);
        }
    }

    // --- Main Event Listeners ---
    addStopToggleBtn.addEventListener('click', showAddRow);
    
    stopsTableBody.addEventListener('click', (event) => {
        const target = event.target;
        const row = target.closest('tr');
        if (!row) return;

        const stopId = row.getAttribute('data-stop-id');

        if (target.closest('.delete-btn')) {
            stopToDeleteId = stopId;
            deleteModal.classList.remove('hidden');
        } else if (target.closest('.edit-btn')) {
            handleEditMode(row);
        } else if (target.closest('.save-edit-btn')) {
            saveEditedStop(row, stopId);
        } else if (target.closest('.cancel-edit-btn') || target.closest('.cancel-new-btn')) {
            fetchStops();
        } else if (target.closest('.save-new-btn')) {
            handleAddSubmit();
        }
    });

    confirmDeleteBtn.addEventListener('click', () => {
        if (stopToDeleteId) {
            deleteStop(stopToDeleteId);
            deleteModal.classList.add('hidden');
            stopToDeleteId = null;
        }
    });

    cancelDeleteBtn.addEventListener('click', () => {
        deleteModal.classList.add('hidden');
        stopToDeleteId = null;
    });

    fetchStops();
});