import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'EV Fleet Control',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.buildThemeData(false), // Light Theme
            darkTheme: themeProvider.buildThemeData(true), // Dark Theme
            themeMode: themeProvider.themeMode, // Current Mode (Light or Dark)
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
