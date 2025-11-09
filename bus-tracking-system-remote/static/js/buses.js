document.addEventListener('DOMContentLoaded', function () {
    const busesTableBody = document.querySelector('#buses-table-body');
    const addBusToggleBtn = document.getElementById('add-bus-toggle-btn');
    const deleteModal = document.getElementById('delete-modal');
    const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
    const cancelDeleteBtn = document.getElementById('cancel-delete-btn');
    
    // --- STATE MANAGEMENT VARIABLES ---
    let busToDeleteId = null;
    let editingBusId = null; // Tracks which bus is currently being edited
    let isAddingNewBus = false; // Tracks if the "add new bus" form should be visible

    // --- Helper Functions ---
    // A robust function to get the CSRF token from cookies
    function getCsrfToken() {
        let cookieValue = null;
        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i].trim();
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, 'csrftoken'.length + 1) === ('csrftoken' + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring('csrftoken'.length + 1));
                    break;
                }
            }
        }
    return cookieValue;
    }
    async function populateBusLinesDropdown(selectElement, selectedId = null) {
        try {
            const response = await fetch('/api/bus-lines/');
            const data = await response.json();
            const busLines = Array.isArray(data) ? data : data.results;

            selectElement.innerHTML = '<option value="">-- Select a Bus Line --</option>';
            busLines.forEach(line => {
                const isSelected =  line.route_id == selectedId; // ✅ Correct
        selectElement.innerHTML += `<option value="${line.route_id}" ${isSelected ? 'selected' : ''}>${line.route_name}</option>`;
            });
        } catch (error) {
            console.error('Failed to populate bus lines dropdown:', error);
            selectElement.innerHTML = '<option value="">Error loading lines</option>';
        }
    }

    // --- MASTER RENDERING FUNCTION ---
    // This function is now responsible for drawing the entire table based on the state variables.
    async function fetchBuses() {
        try {
            const response = await fetch('/api/buses/');
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            const data = await response.json();
            const buses = Array.isArray(data) ? data : data.results;

            busesTableBody.innerHTML = ''; // Always start with a clean slate

            // Render the "Add New Bus" form if the state is set to true
            if (isAddingNewBus) {
                busesTableBody.innerHTML += `
                    <tr id="add-bus-row">
                        <td class="whitespace-nowrap px-6 py-4 font-medium text-gray-900 dark:text-white">New</td>
                        <td class="whitespace-nowrap px-6 py-4"><input type="text" id="add-license-plate" class="bg-gray-100 dark:bg-gray-700 rounded w-full" placeholder="License Plate" required></td>
                        <td class="whitespace-nowrap px-6 py-4"><input type="text" id="add-qr-code" class="bg-gray-100 dark:bg-gray-700 rounded w-full" placeholder="QR Code" required></td>
                        <td class="whitespace-nowrap px-6 py-4"><select id="add-bus-line-select" class="bg-gray-100 dark:bg-gray-700 rounded w-full" required></select></td>
                        <td class="whitespace-nowrap px-6 py-4 text-left">
                            <button id="save-new-bus-btn" class="text-primary hover:text-primary/80"><span class="material-symbols-outlined">save</span></button>
                            <button id="cancel-new-bus-btn" class="text-red-500 hover:text-red-400"><span class="material-symbols-outlined">cancel</span></button>
                        </td>
                    </tr>
                `;
                const addBusLineSelect = document.getElementById('add-bus-line-select');
                populateBusLinesDropdown(addBusLineSelect);
            }

            // Render the list of buses
            if (buses && buses.length > 0) {
                buses.forEach(bus => {
                    // Check if this is the bus we are currently editing
                    if (bus.bus_id === editingBusId) {
                        const editRowHtml = `
                            <tr class="bg-blue-50 dark:bg-blue-900/50" data-bus-id="${bus.bus_id}">
                                <td class="id-cell whitespace-nowrap px-6 py-4 font-medium text-gray-900 dark:text-white">${bus.bus_id}</td>
                                <td class="license-plate-cell whitespace-nowrap px-6 py-4"><input type="text" value="${bus.license_plate}" class="bg-white dark:bg-gray-700 rounded w-full"></td>
                                <td class="qr-code-cell whitespace-nowrap px-6 py-4"><input type="text" value="${bus.qr_code_value || ''}" class="bg-white dark:bg-gray-700 rounded w-full"></td>
                                <td class="bus-line-cell whitespace-nowrap px-6 py-4"><select class="bg-white dark:bg-gray-700 rounded w-full"></select></td>
                                <td class="actions-cell whitespace-nowrap px-6 py-4 text-right">
                                    <div class="flex items-center justify-end gap-2">
                                        <button class="save-edit-btn text-green-500 hover:text-green-400"><span class="material-symbols-outlined text-xl">done</span></button>
                                        <button class="cancel-edit-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined text-xl">close</span></button>
                                    </div>
                                </td>
                            </tr>
                        `;
                        busesTableBody.innerHTML += editRowHtml;
                        const busLineSelect = busesTableBody.querySelector(`[data-bus-id="${bus.bus_id}"] .bus-line-cell select`);
                        const busLineId = bus.bus_line ? bus.bus_line.route_id : null;
                        populateBusLinesDropdown(busLineSelect, busLineId);
                    } else {
                        // Render a normal, non-editable row
                        const busLineName = bus.bus_line ? bus.bus_line.route_name : 'N/A';
                        const normalRowHtml = `
                            <tr class="hover:bg-gray-50 dark:hover:bg-background-dark" data-bus-id="${bus.bus_id}">
                                <td class="id-cell whitespace-nowrap px-6 py-4 font-medium text-gray-900 dark:text-white">${bus.bus_id}</td>
                                <td class="license-plate-cell whitespace-nowrap px-6 py-4 text-gray-600 dark:text-gray-300">${bus.license_plate}</td>
                                <td class="qr-code-cell whitespace-nowrap px-6 py-4 text-gray-600 dark:text-gray-300">${bus.qr_code_value}</td>
                                <td class="bus-line-cell whitespace-nowrap px-6 py-4 text-gray-600 dark:text-gray-300">${busLineName}</td>
                                <td class="actions-cell whitespace-nowrap px-6 py-4 text-right">
                                    <div class="flex items-center justify-end gap-2">
                                        <button class="edit-btn text-primary hover:text-primary/80"><span class="material-symbols-outlined text-xl">edit</span></button>
                                        <button class="delete-btn text-red-500 hover:text-red-400"><span class="material-symbols-outlined text-xl">delete</span></button>
                                    </div>
                                </td>
                            </tr>
                        `;
                        busesTableBody.innerHTML += normalRowHtml;
                    }
                });
            } else if (!isAddingNewBus) {
                busesTableBody.innerHTML += '<tr><td colspan="5" class="text-center py-4">No buses available.</td></tr>';
            }
        } catch (error) {
            console.error('Failed to fetch buses:', error);
            busesTableBody.innerHTML = '<tr><td colspan="5" class="text-center py-4">Error fetching bus data.</td></tr>';
        }
    }

    // --- API Call Functions ---
    async function addNewBus() {
        const licensePlate = document.getElementById('add-license-plate').value;
        const qrCodeValue = document.getElementById('add-qr-code').value;
        const busLineId = document.getElementById('add-bus-line-select').value;

        // Validate input
        if (!licensePlate.trim()) {
            alert('License plate is required!');
            return;
        }

        try {
            const payload = {
                license_plate: licensePlate.trim(),
                qr_code_value: qrCodeValue ? qrCodeValue.trim() : null,
                bus_line_id: busLineId && busLineId !== '' ? parseInt(busLineId, 10) : null
            };
            
            const response = await fetch('/api/buses/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify(payload)
            });
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`HTTP error! status: ${response.status}. Details: ${JSON.stringify(errorData)}`);
            }
            // On success, reset state and re-render
            isAddingNewBus = false;
            fetchBuses();
        } catch (error) {
            console.error('Failed to add bus:', error);
            alert('Error adding bus: ' + error.message);
        }
    }

    async function saveEditedBus(busId, row) {
        const licensePlate = row.querySelector('.license-plate-cell input').value;
        const qrCodeValue = row.querySelector('.qr-code-cell input').value;
        const busLineId = row.querySelector('.bus-line-cell select').value;
        
        // Validate input
        if (!licensePlate.trim()) {
            alert('License plate is required!');
            return;
        }
        
        try {
            const payload = {
                bus_id: busId,
                license_plate: licensePlate.trim(),
                qr_code_value: qrCodeValue ? qrCodeValue.trim() : null,
                bus_line_id: busLineId && busLineId !== '' ? parseInt(busLineId, 10) : null
            };
            
            const response = await fetch(`/api/buses/${busId}/`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                body: JSON.stringify(payload)
            });
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`HTTP error! status: ${response.status}. Details: ${JSON.stringify(errorData)}`);
            }
            // On success, reset state and re-render
            editingBusId = null;
            fetchBuses();
        } catch (error) {
            console.error('Failed to edit bus:', error);
            alert('Error editing bus: ' + error.message);
        }
    }

    async function deleteBus(busId) {
        try {
            const response = await fetch(`/api/buses/${busId}/`, {
                method: 'DELETE',
                headers: { 'X-CSRFToken': getCsrfToken() }
            });
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            fetchBuses(); // Just re-render on success
        } catch (error) {
            console.error('Failed to delete bus:', error);
            alert('Error deleting bus: ' + error.message);
        }
    }

    // --- EVENT LISTENERS ---
    // The event listeners now just manage state and then call fetchBuses() to update the UI.

    addBusToggleBtn.addEventListener('click', () => {
        isAddingNewBus = !isAddingNewBus; // Toggle the adding state
        editingBusId = null; // Ensure we are not in edit mode
        fetchBuses(); // Re-render the table
    });

    busesTableBody.addEventListener('click', (event) => {
        const target = event.target;
        const row = target.closest('tr');
        if (!row) return;

        // --- ADD FORM ACTIONS ---
        if (target.closest('#save-new-bus-btn')) addNewBus();
        if (target.closest('#cancel-new-bus-btn')) {
            isAddingNewBus = false;
            fetchBuses();
        }

        const busId = row.getAttribute('data-bus-id');
        if (!busId) return; // Ignore clicks if it's not a data row

        // --- EDIT/DELETE ACTIONS ---
        if (target.closest('.edit-btn')) {
            editingBusId = parseInt(busId, 10); // Set the bus to edit
            isAddingNewBus = false; // Ensure we are not in add mode
            fetchBuses(); // Re-render the table in edit mode for this row
        }

        if (target.closest('.delete-btn')) {
            busToDeleteId = busId;
            deleteModal.classList.remove('hidden');
        }

        if (target.closest('.save-edit-btn')) {
            saveEditedBus(parseInt(busId, 10), row);
        }

        if (target.closest('.cancel-edit-btn')) {
            editingBusId = null; // Cancel editing
            fetchBuses(); // Re-render the table in its normal state
        }
    });

    // Event listeners for the delete modal
    confirmDeleteBtn.addEventListener('click', () => {
        if (busToDeleteId) {
            deleteBus(busToDeleteId);
            deleteModal.classList.add('hidden');
            busToDeleteId = null;
        }
    });

    cancelDeleteBtn.addEventListener('click', () => {
        deleteModal.classList.add('hidden');
        busToDeleteId = null;
    });

    // Initial data fetch on page load
    fetchBuses();
});