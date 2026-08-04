import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:seasoul/providers/notification_provider.dart';
import 'package:seasoul/providers/category_provider.dart';
import 'package:seasoul/services/notification_service.dart';
import 'package:seasoul/ui/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize with web fallback
  try {
    if (kIsWeb) {
      // For web, use a try-catch with fallback
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized for web');
      } catch (e) {
        print('⚠️ Web Firebase init failed: $e');
        // Fallback: Initialize without options for web
        await Firebase.initializeApp();
        print('✅ Firebase initialized with fallback for web');
      }
    } else {
      // For mobile
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized for mobile');
    }
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Continue without Firebase if needed
  }
  
  // Initialize notification service (only if Firebase is available)
  try {
    await NotificationService.init();
  } catch (e) {
    print('⚠️ Notification service init failed: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeaSoul Holidays',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0099CC),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}