import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/firestore_service.dart';
import '../services/theme_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const AddVehicleScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _driverPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _isRented = false;
  late double _pickedLat;
  late double _pickedLng;

  @override
  void initState() {
    super.initState();
    _pickedLat = widget.initialLat ?? 9.9312;
    _pickedLng = widget.initialLng ?? 76.2673;
  }

  @override
  void dispose() {
    _idController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _driverNameController.dispose();
    _driverLicenseController.dispose();
    _driverPhoneController.dispose();
    super.dispose();
  }

  void _openLocationPicker(
    BuildContext context,
    double initialLat,
    double initialLng,
    Function(LatLng) onLocationPicked,
  ) {
    LatLng pickedLatLng = LatLng(initialLat, initialLng);
    final pickerMapController = MapController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
              titlePadding: const EdgeInsets.all(20),
              contentPadding: EdgeInsets.zero,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              title: Row(
                children: [
                  Icon(Icons.location_searching_rounded, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'PINPOINT VEHICLE LOCATION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                height: 350,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: pickerMapController,
                      options: MapOptions(
                        initialCenter: pickedLatLng,
                        initialZoom: 14.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        onTap: (tapPosition, point) {
                          setPickerState(() {
                            pickedLatLng = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.advaith.evfleet',
                          tileProvider: NetworkTileProvider(),
                          tileDisplay: const TileDisplay.instantaneous(),
                          panBuffer: 2,
                          keepBuffer: 3,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: pickedLatLng,
                              width: 50,
                              height: 50,
                              alignment: Alignment.bottomCenter,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Card(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            'Lat: ${pickedLatLng.latitude.toStringAsFixed(5)}\nLng: ${pickedLatLng.longitude.toStringAsFixed(5)}\n\n💡 Tap anywhere on the map to pinpoint.',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace', height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    onLocationPicked(pickedLatLng);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
                  ),
                  child: const Text('CONFIRM'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.addVehicle(
        vehicleId: _idController.text.trim(),
        licensePlate: _plateController.text.trim(),
        model: _modelController.text.trim(),
        isRented: _isRented,
        driverName: _isRented ? _driverNameController.text.trim() : null,
        driverLicense: _isRented ? _driverLicenseController.text.trim() : null,
        driverPhone: _isRented ? _driverPhoneController.text.trim() : null,
        latitude: _pickedLat,
        longitude: _pickedLng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add vehicle: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final secondaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131B2E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'DEPLOY NEW VEHICLE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glows in Dark Mode
          if (isDark) ...[
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // Form Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Base Vehicle Details Card
                    _buildFormSection(
                      title: 'VEHICLE INFORMATION',
                      icon: Icons.directions_car_rounded,
                      isDark: isDark,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _idController,
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
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _plateController,
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
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _modelController,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Deploy Location Card
                    _buildFormSection(
                      title: 'DEPLOYMENT LOCATION',
                      icon: Icons.location_on_rounded,
                      isDark: isDark,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PINPOINT COORDINATES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lat: ${_pickedLat.toStringAsFixed(5)}\nLng: ${_pickedLng.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              _openLocationPicker(
                                context,
                                _pickedLat,
                                _pickedLng,
                                (point) {
                                  setState(() {
                                    _pickedLat = point.latitude;
                                    _pickedLng = point.longitude;
                                  });
                                },
                              );
                            },
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('PICK ON MAP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rental Assignment Section
                    _buildFormSection(
                      title: 'SHIFT RENTAL ASSIGNMENT',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mark as Rented (In Shift)',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Switch(
                                value: _isRented,
                                activeThumbColor: primaryColor,
                                activeTrackColor: primaryColor.withValues(alpha: 0.3),
                                onChanged: (val) {
                                  setState(() {
                                    _isRented = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isRented) ...[
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _driverNameController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: const InputDecoration(
                                labelText: "Driver's Full Name",
                                hintText: 'Enter driver name',
                              ),
                              validator: (value) {
                                if (_isRented && (value == null || value.trim().isEmpty)) {
                                  return "Please enter driver's name";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _driverLicenseController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: const InputDecoration(
                                labelText: "Driver's License Number",
                                hintText: 'e.g., KL-01-2022-1234567',
                              ),
                              validator: (value) {
                                if (_isRented) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter license number";
                                  }
                                  final cleaned = value.trim();
                                  final dlRegex = RegExp(
                                    r'^[A-Za-z]{2}[-\s]?[0-9]{2}[-\s]?[0-9]{4}[-\s]?[0-9]{7}$',
                                  );
                                  if (!dlRegex.hasMatch(cleaned)) {
                                    return 'Invalid Indian DL format\n(e.g., KL-01-2022-1234567)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _driverPhoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: const InputDecoration(
                                labelText: "Driver's Phone Number",
                                hintText: '10-digit number',
                              ),
                              validator: (value) {
                                if (_isRented) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter phone number";
                                  }
                                  final cleaned = value.trim().replaceAll(RegExp(r'[-\s()+]'), '');
                                  final phoneRegex = RegExp(r'^(?:91)?[6-9][0-9]{9}$');
                                  if (!phoneRegex.hasMatch(cleaned)) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Deployment Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!_isLoading)
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? const Color(0xFF0A0F1D) : Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('DEPLOY VEHICLE'),
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
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
