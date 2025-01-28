import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tagtime_medicare/screens/Caregiver_screen.dart';
import 'package:tagtime_medicare/screens/admin_page.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/medication_service.dart';
import 'package:tagtime_medicare/screens/notification_detail_page.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';
import 'package:tagtime_medicare/screens/profile_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

// 1) ประกาศ navigatorKey เป็น GlobalKey<NavigatorState> เพื่อใช้ใน onDidReceiveNotificationResponse
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    await Firebase.initializeApp();

    await setupTimezone();
    // 2) เรียก initialize service (ซึ่งจะมีการตั้งค่า onDidReceiveNotificationResponse ไว้ด้วย)
    await NotificationService().initialize();

    // เพิ่ม error handling สำหรับ NFC (หากใช้งาน)
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
Future<void> setupTimezone() async {
  String timezone = await FlutterTimezone.getLocalTimezone();
  print("🌍 Device Timezone: $timezone");
}


class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 3) กำหนด navigatorKey ให้กับ MaterialApp
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tagtime Medicare',
      theme: ThemeData(
        fontFamily: 'Poly', // ใช้ฟอนต์ Poly เป็นฟอนต์หลัก
        primaryColor: const Color(0xFF763355), // กำหนดสีหลักให้เข้า Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF4E0),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(), // ใช้ AuthWrapper เป็นหน้าเริ่มต้น
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
        // 4) หน้าแสดงผลเมื่อคลิก Notification
        '/notification_detail': (context) => const NotificationDetailPage(
              payload: '',
            ),
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

        if (snapshot.hasData) {
          // ✅ ถ้าผู้ใช้ล็อกอิน ให้เริ่มฟังการเปลี่ยนแปลงของยา
          final userId = snapshot.data!.uid;
          MedicationService().listenToMedicationChanges(userId); // ✅ เรียกฟังก์ชัน

          return SplashScreen();
        } else {
          return WelcomePage();
        }
      },
    );
  }
}