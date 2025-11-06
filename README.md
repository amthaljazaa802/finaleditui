# Bus Tracking System Backend

A Django REST API for managing and tracking buses, routes, stops, and real-time location updates with ETA calculations.

## Features

- **Bus Management**: CRUD operations for buses, including license plates and QR codes.
- **Route Management**: Create and manage bus lines with ordered stops.
- **Stop Management**: Handle bus stops with geographic locations.
- **Real-Time Tracking**: Update bus locations and log historical data.
- **ETA Calculations**: Compute estimated time of arrival to next and subsequent stops using haversine distance and latest speed.
- **Alerts**: Automatic alerts for off-route buses.
- **WebSocket Support**: Real-time broadcasts of bus location updates.
- **Authentication**: Token-based authentication for API access.
- **CORS Support**: Enabled for frontend integration.

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/FaresShhaiedeh/Buses_BACK_END.git
   cd Buses_BACK_END
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Database Setup**:
   - The project uses MSSQL Server. Update `BusTrackingSystem/settings.py` with your database credentials.
   - Run migrations:
     ```bash
     python manage.py makemigrations
     python manage.py migrate
     ```

4. **Create a superuser** (optional for admin access):
   ```bash
   python manage.py createsuperuser
   ```

5. **Run the server**:
   ```bash
   python manage.py runserver
   ```
   The API will be available at `http://127.0.0.1:8000/`.

## Usage

### API Endpoints

#### Authentication
- `POST /api/auth/token/` - Obtain auth token (requires username/password).

#### Buses
- `GET /api/buses/` - List all buses.
- `POST /api/buses/` - Create a new bus.
- `GET /api/buses/{id}/` - Retrieve a bus.
- `PUT /api/buses/{id}/` - Update a bus.
- `DELETE /api/buses/{id}/` - Delete a bus.
- `POST /api/buses/{id}/update-location/` - Update bus location (requires lat, lon, optional speed).
- `GET /api/buses/{id}/eta/` - Get ETA to next and subsequent stops.

#### Bus Lines (Routes)
- `GET /api/bus-lines/` - List all routes.
- `POST /api/bus-lines/` - Create a new route.
- `GET /api/bus-lines/{id}/` - Retrieve a route.
- `PUT /api/bus-lines/{id}/` - Update a route.
- `DELETE /api/bus-lines/{id}/` - Delete a route.
- `POST /api/bus-lines/{id}/add-stop/` - Add a stop to a route (requires stop_id and order).
- `GET /api/bus-lines/{id}/stops-with-order/` - Get stops for a route with order.
- `GET /api/bus-lines/{id}/stops-with-eta/?bus_id={bus_id}` - Get stops with ETA for a specific bus.

#### Bus Stops
- `GET /api/bus-stops/` - List all stops.
- `POST /api/bus-stops/` - Create a new stop (requires stop_name, latitude, longitude).
- `GET /api/bus-stops/{id}/` - Retrieve a stop.
- `PUT /api/bus-stops/{id}/` - Update a stop.
- `DELETE /api/bus-stops/{id}/` - Delete a stop.

#### Location Logs
- `GET /api/location-logs/` - List all location logs.

#### Alerts
- `GET /api/alerts/` - List all alerts.

#### WebSockets
- `ws://127.0.0.1:8000/ws/bus-locations/` - Real-time bus location updates (JSON format).

#### Frontend Views (HTML)
- `GET /` - Admin dashboard.
- `GET /buses/` - Manage buses.
- `GET /routes/` - Manage routes.
- `GET /stops/` - Manage stops.
- `GET /drivers/` - Manage drivers (placeholder).
- `GET /routes/{id}/` - Route detail.

### Example API Usage

1. **Update Bus Location**:
   ```bash
   curl -X POST http://127.0.0.1:8000/api/buses/1/update-location/ \
        -H "Authorization: Token YOUR_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"latitude": 37.7749, "longitude": -122.4194, "speed": 50}'
   ```

2. **Get ETA for a Bus**:
   ```bash
   curl -X GET http://127.0.0.1:8000/api/buses/1/eta/ \
        -H "Authorization: Token YOUR_TOKEN"
   ```
   Response:
   ```json
   {
     "speed_kmh": 50.0,
     "arrival_threshold_km": 0.1,
     "next_stop": {"stop_id": 2, "stop_name": "Stop B", "order": 2},
     "eta_to_next_stop_seconds": 360,
     "eta_to_next_stop_minutes": 6.0,
     "eta_to_each_stop": [
       {"stop_id": 2, "stop_name": "Stop B", "order": 2, "eta_seconds": 360, "eta_minutes": 6.0},
       {"stop_id": 3, "stop_name": "Stop C", "order": 3, "eta_seconds": 720, "eta_minutes": 12.0}
     ]
   }
   ```

3. **Connect to WebSocket for Real-Time Updates**:
   Use a WebSocket client (e.g., in JavaScript):
   ```javascript
   const ws = new WebSocket('ws://127.0.0.1:8000/ws/bus-locations/');
   ws.onmessage = function(event) {
       const data = JSON.parse(event.data);
       console.log('Bus update:', data);
   };
   ```
   This will receive live updates whenever a bus location is updated via the API.

- **Django 5.2**: Web framework.
- **Django REST Framework**: For API development.
- **Django Channels**: For WebSocket support.
- **MSSQL Server**: Database.
- **Haversine Formula**: For distance calculations.
- **CORS Headers**: For cross-origin requests.

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature-name`.
3. Commit changes: `git commit -m "Add feature"`.
4. Push to branch: `git push origin feature-name`.
5. Open a pull request.

## License

This project is private and proprietary. Unauthorized use is prohibited.

## Contact

For questions or support, contact the repository owner.