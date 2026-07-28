import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:seasoul/providers/notification_provider.dart';
import 'package:seasoul/services/notification_service.dart';
import 'package:seasoul/ui/splashscreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
      ),
      home:  SplashScreen(),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:seasoul/services/test_connection.dart';
// import 'constants/api_constants.dart';

// void main() {
//   // Print the URL to verify
//   print('🚀 Backend URL: ${ApiConstants.baseUrl}');
//   print('📍 Expected: https://sea-soul-backend.vercel.app');
  
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SeaSoul - Backend Test',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const TestConnectionScreen(),
//     );
//   }
// }