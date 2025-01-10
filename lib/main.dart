import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tagtime_medicare/screens/customer_support_page.dart';
import 'package:tagtime_medicare/screens/edit_information_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';
import 'package:tagtime_medicare/screens/splash_screen.dart';
import 'package:tagtime_medicare/screens/login_page.dart';
import 'package:tagtime_medicare/screens/register_page.dart';
import 'package:tagtime_medicare/screens/forgetpassword_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tagtime Medicare',
      theme: ThemeData(
        fontFamily: 'Poly', // ใช้ฟอนต์ Poly เป็นฟอนต์หลัก
        primarySwatch: Colors.brown,
      ),
      home: AuthWrapper(), // ใช้ AuthWrapper เป็นหน้าเริ่มต้น
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forget-password': (context) => ForgetPasswordScreen(),
        '/splash': (context) => SplashScreen(),
        '/welcome': (context) => WelcomePage(),
        '/edit-information': (context) => EditInformationPage(),
        '/customer-support': (context) => CustomerSupportPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ตรวจสอบสถานะผู้ใช้
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // กำลังโหลด
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // ผู้ใช้ล็อกอิน -> ไปหน้า Splash
          return SplashScreen();
        } else {
          // ผู้ใช้ยังไม่ได้ล็อกอิน -> ไปหน้า Welcome
          return WelcomePage();
        }
      },
    );
  }
}