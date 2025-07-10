import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'page/user_page/start_view.dart';
import 'utils/firebase_utils.dart';
import 'services/data_monitoring/firebase_analytics_service.dart';
import 'services/data_monitoring/data_platform_manager.dart';
import 'services/data_manage/auto_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print(' Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print(' Firebase initialized successfully');

    print(' Initializing Firebase services...');
    await FirebaseUtils.initialize();

    print(' Firebase services initialized successfully');

    // Initialize Comprehensive Data Platform
    print(' Initializing Comprehensive Data Platform...');
    await DataPlatformManager().initialize();
    print(' Comprehensive Data Platform initialized successfully');

    // Initialize Auto Backup Service
    print(' Initializing Auto Backup Service...');
    await AutoBackupService().initialize();
    print(' Auto Backup Service initialized successfully');
  } catch (e) {
    print(' Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracking App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [FirebaseAnalyticsService.observer],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.deepPurple.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),

        // FloatingActionButton Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: const StartView(),
    );
  }
}
