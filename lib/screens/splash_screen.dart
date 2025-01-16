import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tagtime_medicare/screens/home_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart'; // Import หน้า Welcome

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext(); // ใช้ _navigateToNext เพื่อตรวจสอบผู้ใช้
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3)); // เวลาแสดง Splash Screen

    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        // ถ้ามีผู้ใช้ล็อกอินอยู่ -> ไปหน้า Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // ถ้ายังไม่มี -> ไปหน้า Welcome
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0), // สีพื้นหลัง
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้
            Image.asset(
              'images/LOGOAYD.png', // ไฟล์โลโก้
              width: 250,
              height: 180,
            ),
            const SizedBox(height: 20),
            // ข้อความ
            const Text(
              'Tagtime Medicare',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB35750), // สีข้อความ
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Version 1.0',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFB35750), // สีข้อความ
              ),
            ),
          ],
        ),
      ),
    );
  }
}
