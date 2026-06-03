import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../services/geofencing_service.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  Map<String, dynamic>? _activeTrip;
  Map<String, dynamic>? _activeVehicle;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
  }

  /// Checks if this driver has a current active shift checkout in Firestore
  Future<void> _checkActiveTrip() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final trip = await _firestoreService.getActiveDriverTrip(_currentUser.uid);
      if (trip != null) {
        final vehicle = await _firestoreService.getVehicle(trip['vehicleId']);
        setState(() {
          _activeTrip = trip;
          _activeVehicle = vehicle;
        });
      } else {
        setState(() {
          _activeTrip = null;
          _activeVehicle = null;
        });
      }
    } catch (e) {
      debugPrint('Error checking active trip: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Attempts to checkout a vehicle by ID (Plate Number/VIN)
  Future<void> _checkoutVehicle(String vehicleId) async {
    setState(() => _isLoading = true);
    try {
      final vehicle = await _firestoreService.getVehicle(vehicleId);

      if (vehicle == null) {
        _showStatusDialog(
          title: 'Vehicle Not Found',
          message: 'The scanned vehicle ID "$vehicleId" was not found in the database. Start the OBD-II simulator to auto-register it.',
          isSuccess: false,
        );
        return;
      }

      final String status = vehicle['status'] ?? 'available';
      final double soc = (vehicle['socPercent'] as num? ?? 0.0).toDouble();

      // Validation Logic: (status == 'available' && soc_percent > 80)
      if (status != 'available') {
        _showStatusDialog(
          title: 'Checkout Declined',
          message: 'Vehicle $vehicleId is currently marked as "$status". It must be available to checkout.',
          isSuccess: false,
        );
        return;
      }

      if (soc < 80.0) {
        _showStatusDialog(
          title: 'Battery Insufficient',
          message: 'This vehicle battery is only at ${soc.toStringAsFixed(1)}%.\n\n'
              'Safety rules require at least 80.0% battery charge to initiate a shift checkout.',
          isSuccess: false,
        );
        return;
      }

      // Perform checkout
      await _firestoreService.startTrip(
        vehicleId: vehicleId,
        driverId: _currentUser!.uid,
        startSoc: soc,
      );

      _showStatusDialog(
        title: 'Checkout Approved',
        message: 'You have checked out ${vehicle['model']} ($vehicleId).\nHave a safe shift!',
        isSuccess: true,
      );

      await _checkActiveTrip();
    } catch (e) {
      _showStatusDialog(
        title: 'Checkout Error',
        message: 'Could not complete checkout: $e',
        isSuccess: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Performs return shift and updates trip/vehicle records
  Future<void> _returnVehicle() async {
    if (_activeTrip == null || _activeVehicle == null) return;

    setState(() => _isLoading = true);
    try {
      // Fetch latest vehicle state to get end battery SOC
      final vehicle = await _firestoreService.getVehicle(_activeVehicle!['id']);
      final double endSoc = (vehicle?['socPercent'] as num? ?? 100.0).toDouble();

      await _firestoreService.endTrip(
        tripId: _activeTrip!['id'],
        vehicleId: _activeVehicle!['id'],
        endSoc: endSoc,
      );

      _showStatusDialog(
        title: 'Shift Logged Out',
        message: 'Vehicle returned successfully. Battery state: ${endSoc.toStringAsFixed(1)}%. Thank you!',
        isSuccess: true,
      );

      await _checkActiveTrip();
    } catch (e) {
      _showStatusDialog(
        title: 'Return Error',
        message: 'Could not complete return check-in: $e',
        isSuccess: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('SCAN VEHICLE QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.of(context).pop();
                  _checkoutVehicle(code);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _showStatusDialog({required String title, required String message, required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00FFCC))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00FFCC); // Neon Cyan
    final secondaryColor = const Color(0xFF3B82F6); // Electric Blue
    final backgroundColor = const Color(0xFF0F172A); // Deep Slate

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.drive_eta, color: Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            const Text(
              'DRIVER DASHBOARD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _activeTrip == null ? _buildCheckoutPrompt(primaryColor, secondaryColor) : _buildActiveShiftView(primaryColor),
            ),
    );
  }

  Widget _buildCheckoutPrompt(Color primaryColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome Driver Panel
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [secondaryColor.withValues(alpha: 0.1), const Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: secondaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Driver',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${_currentUser?.email ?? 'N/A'}',
                style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
              ),
              const Divider(color: Colors.white10, height: 24),
              const Text(
                'Ready to start your shift? Scan the vehicle QR code located on the dashboard or windshield to check in and initialize telematics.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // QR Scanner Button
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _openQrScanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              side: BorderSide(color: secondaryColor.withValues(alpha: 0.4), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 40, color: secondaryColor),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCAN QR CODE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Camera scanner check-in',
                      style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Quick Manual Bypass for Local Development/Testing
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'DEVELOPMENT SHIFT BYPASS',
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _checkoutVehicle('KL01CB1234'),
          icon: const Icon(Icons.flash_on, size: 18),
          label: const Text('CHECKOUT SIMULATOR VEHICLE (KL01CB1234)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveShiftView(Color primaryColor) {
    final vehicleId = _activeVehicle?['id'] ?? 'KL01CB1234';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final docData = snapshot.data!.data() as Map<String, dynamic>?;
        if (docData == null) {
          return const Center(child: Text('Vehicle data missing in Firestore.', style: TextStyle(color: Colors.white)));
        }

        final soc = (docData['socPercent'] as num? ?? 100.0).toDouble();
        final speed = (docData['speed'] as num? ?? 0.0).toDouble();
        final lat = (docData['latitude'] as num? ?? 9.9312).toDouble();
        final lng = (docData['longitude'] as num? ?? 76.2673).toDouble();

        // Calculate Geofence Distance
        final distanceToDepot = GeofencingService.calculateDistance(lat, lng, GeofencingService.depotLat, GeofencingService.depotLng);
        final isAtDepot = distanceToDepot <= 50.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Shift Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACTIVE SHIFT VEHICLE', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(docData['model'] ?? 'Tata Nexon EV', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(docData['licensePlate'] ?? 'KL-01-CB-1234', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0F172A)),
                        child: const Icon(Icons.electric_car, color: Colors.blueAccent, size: 28),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Real-time telemetry indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTelemetryIndicator(
                        'BATTERY',
                        '${soc.toStringAsFixed(1)}%',
                        soc > 30 ? const Color(0xFF10B981) : Colors.redAccent,
                        Icons.battery_charging_full_rounded,
                      ),
                      _buildTelemetryIndicator(
                        'SPEED',
                        '${speed.toStringAsFixed(1)} km/h',
                        Colors.cyan,
                        Icons.speed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Geofence Return Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAtDepot ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAtDepot ? Icons.gpp_good : Icons.gpp_maybe,
                        color: isAtDepot ? const Color(0xFF10B981) : Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAtDepot ? 'Geofence Check Passed' : 'Geofence Check Pending',
                        style: TextStyle(
                          color: isAtDepot ? const Color(0xFF10B981) : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Depot Center: (${GeofencingService.depotLat}, ${GeofencingService.depotLng})\n'
                    'Current GPS: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})\n'
                    'Distance to Yard: ${distanceToDepot.toStringAsFixed(1)} meters',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, height: 1.5, fontFamily: 'monospace'),
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  if (!isAtDepot)
                    Text(
                      '⚠️ Return vehicle to within 50 meters of the central Taxi Depot yard to enable check-in. Driving simulator loop will automatically return to yard eventually.',
                      style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 16),

                  // End Shift Button (Condition: isAtDepot)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (isAtDepot)
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isAtDepot ? _returnVehicle : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0xFF1E293B), // Match button panel
                        disabledForegroundColor: Colors.blueGrey.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isAtDepot ? 'END SHIFT & CHECKIN' : 'LOCKED: MUST RETURN TO DEPOT',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTelemetryIndicator(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
