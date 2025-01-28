// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tagtime_medicare/screens/Caregiver_screen.dart';
import 'package:tagtime_medicare/screens/admin_page.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
import 'package:tagtime_medicare/screens/profile_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    await Firebase.initializeApp();
    NotificationService().initialize();

    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    };

    runApp(const MyApp());
  }, (error, stack) {
    print('Caught error: $error');
    print('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tagtime Medicare',
      theme: ThemeData(
        fontFamily: 'Poly',
        primaryColor: const Color(0xFF763355),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF4E0),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forget-password': (context) => ForgetPasswordScreen(),
        '/splash': (context) => SplashScreen(),
        '/welcome': (context) => WelcomePage(),
        '/edit-information': (context) => EditInformationPage(),
        '/customer-support': (context) => CustomerSupportPage(),
        '/caregiver': (context) => CaregiverPage(),
        '/profile': (context) => ProfilePage(),
        '/adminpage': (context) => AdminPage(),
        '/assignpage': (context) => AssignPage(),
        '/medicine_detail': (context) {
          print('🛣️ Medicine detail route called');
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            print('⚠️ No arguments passed to medicine detail route');
            return Scaffold(
              body: Center(child: Text('No medicine data available')),
            );
          }

          print('📋 Medicine detail arguments: $args');
          return MedicineDetailPage(
            medicineData: args['medicineData'],
            rfidUID: args['rfidUID'],
          );
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF4E0),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Firebase Auth Error: ${snapshot.error}');
          return Scaffold(
            backgroundColor: Color(0xFFFFF4E0),
            body: Center(
              child: Text(
                'เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;
          NotificationService().listenToMedicationChanges(userId);
          return SplashScreen();
        } else {
          return WelcomePage();
        }
      },
    );
  }
}
