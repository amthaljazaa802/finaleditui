// BusTrackingSystem/static/js/drivers.js

document.addEventListener('DOMContentLoaded', function() {
    const driversTableBody = document.querySelector('#drivers-table-body');
    // سنقوم بإنشاء هذا التابع لاحقًا بعد إضافة نموذج Drivers
    // async function fetchDrivers() {
    //     try {
    //         const response = await fetch('/api/drivers/');
    //         const data = await response.json();
    //
    //         const drivers = data; 
    //
    //         if (drivers && drivers.length > 0) {
    //             driversTableBody.innerHTML = '';
    //             drivers.forEach(driver => {
    //                 const row = `
    //                     <tr>
    //                         <td>${driver.name}</td>
    //                         <td>${driver.contact}</td>
    //                         <td>${driver.assigned_bus}</td>
    //                         <td>...</td>
    //                     </tr>
    //                 `;
    //                 driversTableBody.innerHTML += row;
    //             });
    //         } else {
    //             driversTableBody.innerHTML = '<tr><td colspan="4" class="text-center">لا يوجد سائقون متاحون.</td></tr>';
    //         }
    //     } catch (error) {
    //         console.error('Failed to fetch drivers:', error);
    //         driversTableBody.innerHTML = '<tr><td colspan="4" class="text-center">خطأ في تحميل البيانات.</td></tr>';
    //     }
    // }
    //
    // fetchDrivers();

    // لعرض رسالة مؤقتة حتى نقوم بإنشاء نموذج السائقين
    driversTableBody.innerHTML = '<tr><td colspan="4" class="text-center">سيتم تحميل بيانات السائقين هنا لاحقًا.</td></tr>';
});