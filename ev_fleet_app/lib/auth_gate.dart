import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/driver_dashboard.dart';
import '../services/firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00FFCC); // Neon Cyan

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FFCC)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Fetch User Role from Firestore
        return FutureBuilder<Map<String, dynamic>?>(
          future: FirestoreService().getUserData(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: const Color(0xFF0F172A),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E293B),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.radar,
                          size: 48,
                          color: Color(0xFF00FFCC),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Authorizing Fleet Access...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
              // Graceful error display (e.g. database not initialized or permission error)
              final errorDetails = userSnapshot.error?.toString() ?? 'User profile not found in database.';
              return _buildErrorState(context, user, errorDetails);
            }

            final userData = userSnapshot.data!;
            final role = userData['role'] ?? 'driver';

            if (role == 'manager') {
              return const ManagerDashboard();
            } else {
              return const DriverDashboard();
            }
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, User user, String errorDetails) {
    final primaryColor = const Color(0xFF00FFCC);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Firestore Setup Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The user authenticated successfully, but we could not read the database profile.\n\n'
                  '👉 This usually happens because Cloud Firestore is not enabled yet in your Firebase project.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    'Firebase Project: ev-fleet-advaith-2026\n\n'
                    'Click "Create Database" at:\n'
                    'https://console.firebase.google.com/project/ev-fleet-advaith-2026/firestore',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.cyan,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Temporary role bypass button for offline testing
                ElevatedButton.icon(
                  onPressed: () {
                    // Try to create the user profile if missing
                    FirestoreService().createUserProfile(
                      user.uid,
                      user.displayName ?? 'Fleet Member',
                      user.email ?? '',
                      'driver', // Bypass as driver by default
                    );
                  },
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('PROVISION PROFILE AS DRIVER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    FirestoreService().createUserProfile(
                      user.uid,
                      user.displayName ?? 'Fleet Manager',
                      user.email ?? '',
                      'manager', // Bypass as manager
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('PROVISION PROFILE AS MANAGER'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
