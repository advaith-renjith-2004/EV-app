import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/firestore_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabController;
  final MapController _mapController = MapController();

  Map<String, dynamic>? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _centerMapOn(double lat, double lng, Map<String, dynamic> vehicle) {
    _mapController.move(LatLng(lat, lng), 15.0);
    setState(() {
      _selectedVehicle = vehicle;
      _tabController.animateTo(0); // Switch to Map view tab
    });
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
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              ),
              child: const Icon(Icons.dashboard_customize, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'FLEET CONTROL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'MANAGER',
                style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.blueGrey.shade400,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'LIVE TRACKING'),
            Tab(icon: Icon(Icons.directions_car_outlined), text: 'VEHICLE DIRECTORY'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getVehiclesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)));
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final vehicles = snapshot.data ?? [];

          // Compute status statistics
          final totalVehicles = vehicles.length;
          final rentedCount = vehicles.where((v) => v['status'] == 'rented').length;
          final availableCount = vehicles.where((v) => v['status'] == 'available').length;
          final maintenanceCount = vehicles.where((v) => v['status'] == 'maintenance').length;

          return Column(
            children: [
              // Summary Stats Bar
              _buildStatsBar(
                total: totalVehicles,
                rented: rentedCount,
                available: availableCount,
                maintenance: maintenanceCount,
                primaryColor: primaryColor,
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // Prevent map panning gestures conflict with tab swipe
                  children: [
                    // Tab 1: Live Map View
                    _buildMapView(vehicles, primaryColor, secondaryColor),

                    // Tab 2: Vehicle Directory List View
                    _buildListView(vehicles, primaryColor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Vehicles Configured',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your Dart telematics simulator (`obd_simulator`) to register and push vehicle data to Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Run command in terminal:\ncd obd_simulator && dart run bin/obd_simulator.dart',
                style: TextStyle(color: Colors.cyan, fontFamily: 'monospace', fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar({
    required int total,
    required int rented,
    required int available,
    required int maintenance,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('TOTAL', total.toString(), Colors.white),
          _buildStatItem('RENTED', rented.toString(), const Color(0xFF3B82F6)),
          _buildStatItem('AVAILABLE', available.toString(), const Color(0xFF10B981)),
          _buildStatItem('OFFLINE', maintenance.toString(), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildMapView(List<Map<String, dynamic>> vehicles, Color primaryColor, Color secondaryColor) {
    // Convert Firestore vehicles data to Map markers
    final markers = vehicles.map((v) {
      final lat = v['latitude'] as double? ?? 9.9312;
      final lng = v['longitude'] as double? ?? 76.2673;
      final status = v['status'] as String? ?? 'available';

      Color markerColor;
      IconData markerIcon;
      if (status == 'rented') {
        markerColor = const Color(0xFF3B82F6); // Blue
        markerIcon = Icons.drive_eta;
      } else if (status == 'maintenance') {
        markerColor = Colors.redAccent;
        markerIcon = Icons.build;
      } else {
        markerColor = const Color(0xFF10B981); // Green
        markerIcon = Icons.battery_charging_full_rounded;
      }

      final isSelected = _selectedVehicle != null && _selectedVehicle!['id'] == v['id'];

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 64 : 44,
        height: isSelected ? 64 : 44,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedVehicle = v;
            });
          },
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: markerColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: markerColor, width: isSelected ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF0F172A),
                child: Icon(
                  markerIcon,
                  color: markerColor,
                  size: isSelected ? 24 : 18,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        // Map Container wrapped in inverted color matrix for Dark Mode Look
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            // Dark Inversion Matrix
            -0.8, 0, 0, 0, 255,
            0, -0.8, 0, 0, 255,
            0, 0, -0.75, 0, 255,
            0, 0, 0, 1, 0,
          ]),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(9.9312, 76.2673),
              initialZoom: 14.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.advaith.evfleet',
              ),
            ],
          ),
        ),

        // Normal Markers layered outside of the Dark filter to preserve correct neon colors!
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(9.9312, 76.2673),
            initialZoom: 14.0,
          ),
          children: [
            MarkerLayer(markers: markers),
          ],
        ),

        // Selected Vehicle Info Card floating overlay
        if (_selectedVehicle != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9), // Slate 800
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVehicle!['model'] ?? 'Tata Nexon EV',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedVehicle!['licensePlate'] ?? 'KL-01-CB-1234',
                            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                      _buildStatusBadge(_selectedVehicle!['status'] ?? 'available'),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTelemetryDetail('BATTERY', '${(_selectedVehicle!['socPercent'] as double? ?? 0.0).toStringAsFixed(1)}%',
                          (_selectedVehicle!['socPercent'] as double? ?? 0.0) > 30 ? const Color(0xFF10B981) : Colors.redAccent),
                      _buildTelemetryDetail('SPEED', '${(_selectedVehicle!['speed'] as double? ?? 0.0).toStringAsFixed(1)} km/h', Colors.cyan),
                      _buildTelemetryDetail('LOCATION',
                          '${(_selectedVehicle!['latitude'] as double? ?? 0.0).toStringAsFixed(3)}, ${(_selectedVehicle!['longitude'] as double? ?? 0.0).toStringAsFixed(3)}',
                          Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedVehicle = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('DISMISS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _mapController.move(
                              LatLng(
                                _selectedVehicle!['latitude'] as double? ?? 9.9312,
                                _selectedVehicle!['longitude'] as double? ?? 76.2673,
                              ),
                              16.0,
                            );
                          },
                          icon: const Icon(Icons.gps_fixed, size: 16),
                          label: const Text('CENTER MAP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTelemetryDetail(String label, String value, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> vehicles, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final plate = vehicle['licensePlate'] as String? ?? 'N/A';
        final model = vehicle['model'] as String? ?? 'Electric Vehicle';
        final status = vehicle['status'] as String? ?? 'available';
        final soc = vehicle['socPercent'] as double? ?? 0.0;
        final speed = vehicle['speed'] as double? ?? 0.0;
        final lat = vehicle['latitude'] as double? ?? 9.9312;
        final lng = vehicle['longitude'] as double? ?? 76.2673;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.electric_car,
                          color: status == 'rented' ? const Color(0xFF3B82F6) : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plate,
                            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 16),

              // Battery charge UI
              Row(
                children: [
                  Icon(
                    soc > 80
                        ? Icons.battery_full
                        : soc > 30
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_alert,
                    color: soc > 80
                        ? const Color(0xFF10B981)
                        : soc > 30
                            ? Colors.amber
                            : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Battery Charge: ${soc.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: soc / 100.0,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    soc > 80
                        ? const Color(0xFF10B981)
                        : soc > 30
                            ? Colors.amber
                            : Colors.redAccent,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // Tracking Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.cyan, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${speed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _centerMapOn(lat, lng, vehicle),
                    icon: const Icon(Icons.my_location, size: 14),
                    label: const Text('TRACK ON MAP'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    if (status == 'rented') {
      color = const Color(0xFF3B82F6);
      label = 'IN SHIFT';
    } else if (status == 'maintenance') {
      color = Colors.redAccent;
      label = 'OFFLINE';
    } else {
      color = const Color(0xFF10B981);
      label = 'CHARGING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
