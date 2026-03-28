// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase initialized");
    } else {
      debugPrint("⚠️ Firebase already initialized");
    }
  } catch (e) {
    debugPrint("🔥 Firebase init error (ignored): $e");
  }

  // Lock orientation (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..listenToAuth(),
      child: const RSUPortalApp(),
    ),
  );
}

class RSUPortalApp extends StatelessWidget {
  const RSUPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppProvider>().themeMode;
    return MaterialApp(
      title: 'RSU Student Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}