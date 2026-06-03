import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String _selectedRole = 'driver'; // Default role
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _getCleanErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'This email address is already in use.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return e.message ?? 'An authentication error occurred.';
      }
    }
    
    final errorStr = e.toString();
    if (errorStr.contains('permission-denied') || errorStr.contains('PERMISSION_DENIED')) {
      return 'Database access denied. Please check your database rules.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        // Register user
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          try {
            // Save role to Firestore
            await _firestoreService.createUserProfile(
              userCredential.user!.uid,
              _nameController.text.trim(),
              _emailController.text.trim(),
              _selectedRole,
            );
          } catch (firestoreError) {
            // Rollback auth registration if database creation fails
            await userCredential.user!.delete();
            rethrow;
          }
        }
      } else {
        // Log in user
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getCleanErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getCleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      body: Stack(
        children: [
          // Ambient Glowing Blobs (only in dark mode for premium futuristic feel)
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -100,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -150,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Blur Filter overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // Main Layout Content
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo & Title
                          Column(
                            children: [
                              Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.35),
                                      blurRadius: 35,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [primaryColor, Colors.white],
                                ).createShader(bounds),
                                child: const Text(
                                  'VOLTFLEET',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'EV Command & Checkout Telematics',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Card containing forms (Glassmorphic look)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(28.0),
                                decoration: BoxDecoration(
                                  color: (isDark
                                      ? const Color(0xFF131B2E).withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.9)),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _isSignUp ? 'Create Fleet Account' : 'Control Center Sign-In',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          letterSpacing: 0.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),

                                      // Error message Banner
                                      if (_errorMessage != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          margin: const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                                          ),
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                      // Name Field (Only Sign Up)
                                      if (_isSignUp) ...[
                                        TextFormField(
                                          controller: _nameController,
                                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                          decoration: _buildInputDecoration(
                                            label: 'Full Name',
                                            icon: Icons.person_outline,
                                            accentColor: primaryColor,
                                            isDark: isDark,
                                          ),
                                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: _buildInputDecoration(
                                          label: 'Email Address',
                                          icon: Icons.email_outlined,
                                          accentColor: primaryColor,
                                          isDark: isDark,
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Enter email';
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                            return 'Enter valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Password Field
                                      TextFormField(
                                        controller: _passwordController,
                                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        obscureText: true,
                                        decoration: _buildInputDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          accentColor: primaryColor,
                                          isDark: isDark,
                                        ),
                                        validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ chars' : null,
                                      ),
                                      const SizedBox(height: 20),

                                      // Role Selector (Only Sign Up)
                                      if (_isSignUp) ...[
                                        Text(
                                          'Register As:',
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildRoleButton(
                                                label: 'Driver',
                                                role: 'driver',
                                                icon: Icons.drive_eta,
                                                activeColor: secondaryColor,
                                                isDark: isDark,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildRoleButton(
                                                label: 'Manager',
                                                role: 'manager',
                                                icon: Icons.admin_panel_settings,
                                                activeColor: primaryColor,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                      ],

                                      // Submit Button
                                      Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isSignUp && _selectedRole == 'manager' ? primaryColor : secondaryColor)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            )
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: _isSignUp && _selectedRole == 'manager'
                                                    ? [primaryColor, primaryColor.withValues(alpha: 0.8)]
                                                    : [secondaryColor, secondaryColor.withValues(alpha: 0.8)],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Text(
                                                      _isSignUp ? 'REGISTER' : 'LOG IN',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required String role,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF070B14).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.blueGrey.shade400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.blueGrey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    final textMuted = isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: textMuted, size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF070B14).withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.02),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
    );
  }
}
