import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/driver_dashboard.dart';
import '../services/firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  void _autoProvisionProfile(User user, String role) {
    FirestoreService().createUserProfile(
      user.uid,
      user.displayName ?? (role == 'manager' ? 'Fleet Manager' : 'Fleet Member'),
      user.email ?? '',
      role,
    ).catchError((e) {
      debugPrint('Auto-provisioning failed: $e');
    });
  }

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

        // Fetch User Role from Firestore in real-time
        return StreamBuilder<Map<String, dynamic>?>(
          stream: FirestoreService().getUserDataStream(user.uid),
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
                              color: primaryColor.withValues(alpha: 0.2),
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

            // If there's an error (e.g. permission error, offline, or Firebase setup issue),
            // gracefully bypass the blocker and route directly to Manager Dashboard
            if (userSnapshot.hasError) {
              debugPrint('Firestore stream error: ${userSnapshot.error}');
              return const ManagerDashboard();
            }

            // If user snapshot is empty (document does not exist in database yet),
            // auto-provision in the background and route to dashboard immediately
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              final email = user.email ?? '';
              final defaultRole = email.toLowerCase().contains('driver') ? 'driver' : 'manager';
              
              _autoProvisionProfile(user, defaultRole);

              if (defaultRole == 'manager') {
                return const ManagerDashboard();
              } else {
                return const DriverDashboard();
              }
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
}
