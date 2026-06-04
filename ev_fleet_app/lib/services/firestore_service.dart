import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Stream of all vehicles in the fleet for real-time tracking
  Stream<List<Map<String, dynamic>>> getVehiclesStream() {
    return _db.collection('vehicles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get specific vehicle document by ID
  Future<Map<String, dynamic>?> getVehicle(String vehicleId) async {
    final doc = await _db.collection('vehicles').doc(vehicleId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  /// Fetches the user document to determine role ('manager' vs 'driver')
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    // Check manager collection first
    var doc = await _db.collection('manager').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['role'] = 'manager';
      return data;
    }

    // Check driver collection
    doc = await _db.collection('driver').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['role'] = 'driver';
      return data;
    }

    return null;
  }

  /// Stream user document to react to profile provisioning dynamically
  Stream<Map<String, dynamic>?> getUserDataStream(String uid) {
    final controller = StreamController<Map<String, dynamic>?>();
    StreamSubscription? managerSub;
    StreamSubscription? driverSub;

    // Do a quick check on where the user document exists to setup the snapshots subscription
    _db.collection('manager').doc(uid).get().then((managerDoc) {
      if (managerDoc.exists) {
        managerSub = _db.collection('manager').doc(uid).snapshots().listen(
          (snap) {
            if (snap.exists) {
              final data = snap.data();
              if (data != null) {
                data['role'] = 'manager';
                controller.add(data);
              }
            } else {
              controller.add(null);
            }
          },
          onError: controller.addError,
        );
      } else {
        driverSub = _db.collection('driver').doc(uid).snapshots().listen(
          (snap) {
            if (snap.exists) {
              final data = snap.data();
              if (data != null) {
                data['role'] = 'driver';
                controller.add(data);
              }
            } else {
              controller.add(null);
            }
          },
          onError: controller.addError,
        );
      }
    }).catchError((e) {
      // Gracefully fall back to subscribing to the driver stream if manager check fails
      driverSub = _db.collection('driver').doc(uid).snapshots().listen(
        (snap) {
          if (snap.exists) {
            final data = snap.data();
            if (data != null) {
              data['role'] = 'driver';
              controller.add(data);
            }
          } else {
            controller.add(null);
          }
        },
        onError: controller.addError,
      );
    });

    controller.onCancel = () {
      managerSub?.cancel();
      driverSub?.cancel();
    };

    return controller.stream;
  }

  /// Creates a new user profile upon registration
  Future<void> createUserProfile(String uid, String name, String email, String role) async {
    final collectionName = (role == 'manager') ? 'manager' : 'driver';
    await _db.collection(collectionName).doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
    });
  }

  /// Updates user profile details like name and photo
  Future<void> updateUserProfile(String uid, {String? name, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    if (updates.isEmpty) return;

    // Check manager collection first
    final managerDoc = await _db.collection('manager').doc(uid).get();
    if (managerDoc.exists) {
      await _db.collection('manager').doc(uid).update(updates);
      return;
    }

    // Check driver collection
    final driverDoc = await _db.collection('driver').doc(uid).get();
    if (driverDoc.exists) {
      await _db.collection('driver').doc(uid).update(updates);
      return;
    }
  }

  /// Adds a new vehicle to the database
  Future<void> addVehicle({
    required String vehicleId,
    required String licensePlate,
    required String model,
    bool isRented = false,
    String? driverName,
    String? driverLicense,
    String? driverPhone,
  }) async {
    final vehicleData = <String, dynamic>{
      'id': vehicleId,
      'licensePlate': licensePlate,
      'model': model,
      'status': isRented ? 'rented' : 'available',
      'socPercent': 100.0,
      'latitude': 9.9312, // Depot Lat
      'longitude': 76.2673, // Depot Lng
      'speed': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (isRented) {
      vehicleData['driverName'] = driverName;
      vehicleData['driverLicense'] = driverLicense;
      vehicleData['driverPhone'] = driverPhone;
    }

    await _db.collection('vehicles').doc(vehicleId).set(vehicleData);
  }

  /// Starts a checkout trip for a driver
  Future<void> startTrip({
    required String vehicleId,
    required String driverId,
    required double startSoc,
  }) async {
    final tripId = _uuid.v4();
    final batch = _db.batch();

    // 1. Create trip record
    final tripRef = _db.collection('trips').doc(tripId);
    batch.set(tripRef, {
      'id': tripId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'startSoc': startSoc,
      'endSoc': null,
    });

    // 2. Update vehicle status to 'rented'
    final vehicleRef = _db.collection('vehicles').doc(vehicleId);
    batch.update(vehicleRef, {
      'status': 'rented',
    });

    await batch.commit();
  }

  /// Ends a driver's trip, charging vehicle back to 'available'
  Future<void> endTrip({
    required String tripId,
    required String vehicleId,
    required double endSoc,
  }) async {
    final batch = _db.batch();

    // 1. Update trip record
    final tripRef = _db.collection('trips').doc(tripId);
    batch.update(tripRef, {
      'endTime': FieldValue.serverTimestamp(),
      'endSoc': endSoc,
    });

    // 2. Set vehicle status back to 'available'
    final vehicleRef = _db.collection('vehicles').doc(vehicleId);
    batch.update(vehicleRef, {
      'status': 'available',
    });

    await batch.commit();
  }

  /// Checks if a driver has an active checked-out trip
  Future<Map<String, dynamic>?> getActiveDriverTrip(String driverId) async {
    final query = await _db
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('endTime', isNull: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }
    return null;
  }
}
