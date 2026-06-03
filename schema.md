# Firestore Database Schema

## 1. `users` Collection
Stores details of registered users and their corresponding roles.
- **Path**: `/users/{uid}`
- **Document Structure**:
  ```json
  {
    "uid": "USER_AUTH_UID_STRING",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "role": "manager" // Can be "manager" or "driver"
  }
  ```

## 2. `vehicles` Collection
Stores the static configuration and real-time OBD-II telematics of each electric vehicle in the fleet.
- **Path**: `/vehicles/{vehicleId}` (where `vehicleId` can be the license plate or VIN, e.g., `KL01CB1234`)
- **Document Structure**:
  ```json
  {
    "id": "KL01CB1234",
    "licensePlate": "KL-01-CB-1234",
    "model": "Tata Nexon EV",
    "status": "available", // "available", "rented", "maintenance"
    "socPercent": 92.5, // State of Charge (Battery %)
    "latitude": 9.9312, // Dynamic GPS coordinate
    "longitude": 76.2673, // Dynamic GPS coordinate
    "speed": 45.2, // Current speed in km/h
    "lastUpdated": "2026-06-03T13:00:00.000Z" // Firestore Timestamp
  }
  ```

## 3. `trips` Collection
Logs checkout sessions when a driver starts and ends their shift.
- **Path**: `/trips/{tripId}`
- **Document Structure**:
  ```json
  {
    "id": "TRIP_UUID_STRING",
    "vehicleId": "KL01CB1234",
    "driverId": "DRIVER_AUTH_UID_STRING",
    "startTime": "2026-06-03T08:00:00.000Z", // Firestore Timestamp
    "endTime": null, // Firestore Timestamp (null if active)
    "startSoc": 95.0, // Battery % at start
    "endSoc": null // Battery % at end (null if active)
  }
  ```
