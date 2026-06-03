import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

// Firebase configuration
const String projectId = 'ev-fleet-advaith-2026';
const String vehicleId = 'KL01CB1234';

// Taxi Depot coordinates (Kochi, India)
const double depotLat = 9.9312;
const double depotLng = 76.2673;

// Simulated driving route waypoints (a circuit starting and ending at the depot)
final List<Map<String, double>> waypoints = [
  {'lat': 9.9312, 'lng': 76.2673}, // Depot
  {'lat': 9.9325, 'lng': 76.2685},
  {'lat': 9.9340, 'lng': 76.2698},
  {'lat': 9.9355, 'lng': 76.2710},
  {'lat': 9.9372, 'lng': 76.2725},
  {'lat': 9.9388, 'lng': 76.2710},
  {'lat': 9.9395, 'lng': 76.2692},
  {'lat': 9.9380, 'lng': 76.2670},
  {'lat': 9.9360, 'lng': 76.2655},
  {'lat': 9.9335, 'lng': 76.2648},
  {'lat': 9.9320, 'lng': 76.2660},
  {'lat': 9.9312, 'lng': 76.2673}, // Back to Depot
];

int currentWaypointIndex = 0;
double socPercent = 95.0; // Starting battery %
String status = 'available'; // 'available', 'rented', 'maintenance'
double currentLat = depotLat;
double currentLng = depotLng;
double speed = 0.0;

final Random random = Random();

Future<void> main() async {
  print('========================================');
  print('🚗 EV OBD-II Telematics Simulator Active');
  print('Project: $projectId');
  print('Vehicle ID: $vehicleId');
  print('Interval: 5 seconds');
  print('========================================\n');

  // Initial push to make sure the vehicle document exists in Firestore
  await pushToFirestore();

  // Run simulation loop every 5 seconds
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      // 1. Fetch current status from Firestore in case the driver app updated it
      await fetchCurrentStatus();

      // 2. Perform simulation step based on vehicle status
      if (status == 'rented') {
        simulateDriving();
      } else if (status == 'available') {
        simulateCharging();
      } else {
        simulateMaintenance();
      }

      // 3. Push telemetry data back to Firestore
      await pushToFirestore();
    } catch (e) {
      print('⚠️ Error in simulation loop: $e');
    }
  });
}

/// Fetches the latest vehicle document from Firestore to check if status was updated by the app (e.g., driver checks it out)
Future<void> fetchCurrentStatus() async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/vehicles/$vehicleId',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fields = data['fields'] as Map<String, dynamic>?;

      if (fields != null) {
        if (fields.containsKey('status')) {
          status = fields['status']['stringValue'] ?? 'available';
        }
        if (fields.containsKey('socPercent')) {
          final socVal = fields['socPercent']['doubleValue'] ?? fields['socPercent']['integerValue'];
          if (socVal != null) {
            socPercent = socVal.toDouble();
          }
        }
      }
    } else if (response.statusCode == 404) {
      print('ℹ️ Vehicle document not found. It will be created on the next push.');
    } else {
      print('⚠️ Failed to fetch vehicle status: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('⚠️ Error fetching vehicle status: $e');
  }
}

/// Simulates vehicle movement and battery drain when checked out ('rented')
void simulateDriving() {
  // Move to the next waypoint
  currentWaypointIndex = (currentWaypointIndex + 1) % waypoints.length;
  final nextPoint = waypoints[currentWaypointIndex];
  
  currentLat = nextPoint['lat']!;
  currentLng = nextPoint['lng']!;
  
  // Random speed between 30 and 55 km/h
  speed = 30.0 + random.nextDouble() * 25.0;
  
  // Battery consumption: drain 0.5% to 1.0% per waypoint step
  final consumption = 0.5 + random.nextDouble() * 0.5;
  socPercent = max(0.0, socPercent - consumption);
  
  print('➡️ DRIVING: Location: ($currentLat, $currentLng) | Speed: ${speed.toStringAsFixed(1)} km/h | Battery: ${socPercent.toStringAsFixed(1)}%');

  // Auto transition to maintenance/stopped if battery is completely empty
  if (socPercent <= 0.0) {
    status = 'maintenance';
    speed = 0.0;
    print('⚠️ Battery depleted! Vehicle entered maintenance mode.');
  }
}

/// Simulates vehicle charging at the depot when 'available'
void simulateCharging() {
  currentLat = depotLat;
  currentLng = depotLng;
  speed = 0.0;

  // Charge battery: charge by 1.0% to 2.0% per step until 100%
  if (socPercent < 100.0) {
    final charge = 1.0 + random.nextDouble() * 1.0;
    socPercent = min(100.0, socPercent + charge);
    print('🔌 CHARGING: Battery: ${socPercent.toStringAsFixed(1)}% (Parked at Depot)');
  } else {
    print('🔋 CHARGED: Battery: 100% (Parked at Depot - Available for checkout)');
  }
}

/// Simulates parked vehicle in maintenance mode
void simulateMaintenance() {
  speed = 0.0;
  print('🛠️ MAINTENANCE: Vehicle is static at ($currentLat, $currentLng) | Battery: ${socPercent.toStringAsFixed(1)}%');
}

/// Pushes the dynamic telemetry data to Firestore using the REST API
Future<void> pushToFirestore() async {
  // Note: We use the PATCH method to update fields. If the document doesn't exist, it creates it.
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/vehicles/$vehicleId'
    '?updateMask.fieldPaths=id'
    '&updateMask.fieldPaths=licensePlate'
    '&updateMask.fieldPaths=model'
    '&updateMask.fieldPaths=status'
    '&updateMask.fieldPaths=socPercent'
    '&updateMask.fieldPaths=latitude'
    '&updateMask.fieldPaths=longitude'
    '&updateMask.fieldPaths=speed'
    '&updateMask.fieldPaths=lastUpdated',
  );

  final payload = {
    'fields': {
      'id': {'stringValue': vehicleId},
      'licensePlate': {'stringValue': 'KL-01-CB-1234'},
      'model': {'stringValue': 'Tata Nexon EV'},
      'status': {'stringValue': status},
      'socPercent': {'doubleValue': socPercent},
      'latitude': {'doubleValue': currentLat},
      'longitude': {'doubleValue': currentLng},
      'speed': {'doubleValue': speed},
      'lastUpdated': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    }
  };

  try {
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // Telemetry pushed successfully
    } else {
      print('❌ Failed to push telematics: ${response.statusCode} - ${response.body}');
      if (response.body.contains('Cloud Firestore API has not been used')) {
        print('\n👉 IMPORTANT: Please enable Cloud Firestore in your Firebase project:');
        print('👉 https://console.firebase.google.com/project/$projectId/firestore\n');
      }
    }
  } catch (e) {
    print('❌ Error pushing to Firestore: $e');
  }
}
