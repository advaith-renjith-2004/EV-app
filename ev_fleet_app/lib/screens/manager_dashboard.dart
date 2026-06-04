import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/theme_provider.dart';
import 'profile_screen.dart';

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
  bool _isSearching = false;
  String _searchQuery = '';

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

  void _showAddVehicleDialog() {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final plateController = TextEditingController();
    final modelController = TextEditingController();
    final driverNameController = TextEditingController();
    final driverLicenseController = TextEditingController();
    final driverPhoneController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    bool isLoading = false;
    bool isRented = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.electric_car, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'ADD NEW VEHICLE',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: idController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Vehicle ID (e.g., v001)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vehicle ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: plateController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'License Plate (e.g., KL-01-CB-1234)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter license plate';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: modelController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Model (e.g., Tata Nexon EV)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter vehicle model';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mark as Rented (In Shift)',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Switch(
                            value: isRented,
                            activeThumbColor: primaryColor,
                            activeTrackColor: primaryColor.withValues(alpha: 0.3),
                            onChanged: (val) {
                              setDialogState(() {
                                isRented = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (isRented) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: driverNameController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            labelText: "Driver's Full Name",
                            hintText: 'Enter driver name',
                          ),
                          validator: (value) {
                            if (isRented && (value == null || value.trim().isEmpty)) {
                              return "Please enter driver's name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: driverLicenseController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            labelText: "Driver's License Number",
                            hintText: 'Enter license number',
                          ),
                          validator: (value) {
                            if (isRented && (value == null || value.trim().isEmpty)) {
                              return "Please enter license number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: driverPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            labelText: "Driver's Phone Number",
                            hintText: 'Enter phone number',
                          ),
                          validator: (value) {
                            if (isRented && (value == null || value.trim().isEmpty)) {
                              return "Please enter phone number";
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isLoading = true;
                            });

                            try {
                              await _firestoreService.addVehicle(
                                vehicleId: idController.text.trim(),
                                licensePlate: plateController.text.trim(),
                                model: modelController.text.trim(),
                                isRented: isRented,
                                driverName: isRented ? driverNameController.text.trim() : null,
                                driverLicense: isRented ? driverLicenseController.text.trim() : null,
                                driverPhone: isRented ? driverPhoneController.text.trim() : null,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vehicle added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isLoading = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add vehicle: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? const Color(0xFF0A0F1D) : Colors.white,
                            ),
                          ),
                        )
                      : const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white10,
        child: Icon(Icons.person, color: Colors.white70, size: 20),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firestoreService.getUserDataStream(user.uid),
      builder: (context, snapshot) {
        ImageProvider? imageProvider;
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          final photoUrl = data['photoUrl'] as String?;
          if (photoUrl != null && photoUrl.isNotEmpty) {
            if (photoUrl.startsWith('data:image')) {
              try {
                imageProvider = MemoryImage(base64Decode(photoUrl.split(',')[1]));
              } catch (_) {}
            } else {
              imageProvider = NetworkImage(photoUrl);
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF131B2E),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, color: Colors.white70, size: 20)
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'VOLTFLEET',
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
                color: primaryColor.withValues(alpha: 0.1),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildProfileIcon(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: primaryColor.withValues(alpha: 0.12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5),
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'LIVE TRACKING'),
            Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'VEHICLE DIRECTORY'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        backgroundColor: primaryColor,
        foregroundColor: const Color(0xFF0F172A),
        tooltip: 'Add Vehicle',
        child: const Icon(Icons.add),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.7 : 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('TOTAL', total.toString(), isDark ? Colors.white : const Color(0xFF0F172A), Colors.blueGrey),
                _buildStatItem('RENTED', rented.toString(), const Color(0xFF3B82F6), const Color(0xFF3B82F6)),
                _buildStatItem('AVAILABLE', available.toString(), const Color(0xFF10B981), const Color(0xFF10B981)),
                _buildStatItem('OFFLINE', maintenance.toString(), Colors.redAccent, Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor, Color badgeColor) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
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
                color: markerColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: markerColor, width: isSelected ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.3),
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
        // Consolidated single map instance to avoid overlapping Canvas canvas backgrounds
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(9.9312, 76.2673),
            initialZoom: 14.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // Dark Inversion Matrix applied directly inside map children
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                -0.8, 0, 0, 0, 255,
                0, -0.8, 0, 0, 255,
                0, 0, -0.75, 0, 255,
                0, 0, 0, 1, 0,
              ]),
              child: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.advaith.evfleet',
              ),
            ),
            // Layer markers directly on top of tiles within the same map
            MarkerLayer(markers: markers),
          ],
        ),

        // Floating Search Overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _isSearching
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search vehicle by model or plate...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: primaryColor),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchQuery = '';
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                          if (_searchQuery.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: vehicles
                                    .where((v) =>
                                        (v['model'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                        (v['licensePlate'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
                                    .map((v) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(v['model'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    subtitle: Text(v['licensePlate'] ?? '', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                                    trailing: _buildStatusBadge(v['status'] ?? 'available'),
                                    onTap: () {
                                      final lat = v['latitude'] as double? ?? 9.9312;
                                      final lng = v['longitude'] as double? ?? 76.2673;
                                      _centerMapOn(lat, lng, v);
                                      setState(() {
                                        _isSearching = false;
                                        _searchQuery = '';
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.topRight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                        backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
                        foregroundColor: primaryColor,
                        child: const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ),
                ),
        ),

        // Selected Vehicle Info Card floating overlay
        if (_selectedVehicle != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))
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
                      const Divider(color: Colors.white10, height: 24),
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
                      const SizedBox(height: 16),
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
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

        Color statusColor;
        if (status == 'rented') {
          statusColor = const Color(0xFF3B82F6);
        } else if (status == 'maintenance') {
          statusColor = Colors.redAccent;
        } else {
          statusColor = const Color(0xFF10B981);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: statusColor,
                    width: 6,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(20),
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
                              color: isDark ? const Color(0xFF0A0F1D) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.electric_car,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plate,
                                style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Battery charge UI
                  Row(
                    children: [
                      Icon(
                        soc > 80
                            ? Icons.battery_full_rounded
                            : soc > 30
                                ? Icons.battery_charging_full_rounded
                                : Icons.battery_alert_rounded,
                        color: soc > 80
                            ? const Color(0xFF10B981)
                            : soc > 30
                                ? Colors.amber
                                : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Battery Charge: ${soc.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: soc / 100.0,
                      backgroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        soc > 80
                            ? const Color(0xFF10B981)
                            : soc > 30
                                ? Colors.amber
                                : Colors.redAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (status == 'rented' && (vehicle['driverName'] != null || vehicle['driverLicense'] != null)) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 14, color: statusColor),
                              const SizedBox(width: 8),
                              Text(
                                'RENTAL DRIVER INFO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (vehicle['driverName'] != null)
                            _buildDriverMetaRow('Driver Name', vehicle['driverName'].toString(), isDark),
                          if (vehicle['driverLicense'] != null) ...[
                            const SizedBox(height: 6),
                            _buildDriverMetaRow('License No', vehicle['driverLicense'].toString(), isDark),
                          ],
                          if (vehicle['driverPhone'] != null) ...[
                            const SizedBox(height: 6),
                            _buildDriverMetaRow('Contact No', vehicle['driverPhone'].toString(), isDark),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Tracking Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Colors.cyan, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${speed.toStringAsFixed(1)} km/h',
                            style: const TextStyle(color: Colors.cyan, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _centerMapOn(lat, lng, vehicle),
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('TRACK ON MAP'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDriverMetaRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.blueGrey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
