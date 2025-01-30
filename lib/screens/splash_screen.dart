import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tagtime_medicare/screens/home_page.dart';
import 'package:tagtime_medicare/screens/welcome.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  bool _showText = false;
  bool _showVersion = false;
  double _logoSize = 150;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // เริ่มแสดง Logo ด้วย fade in
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showLogo = true);

    // ทำให้ Logo ขยายขึ้น
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _logoSize = 250);

    // แสดงชื่อแอพ
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showText = true);

    // แสดงเวอร์ชัน
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showVersion = true);

    // รอก่อนไปหน้าถัดไป
    await Future.delayed(const Duration(seconds: 1));
    _navigateToNext();
  }

  void _navigateToNext() async {
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (user != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => WelcomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showLogo ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: _logoSize,
                height: _logoSize * 0.72, // รักษาอัตราส่วน
                curve: Curves.easeOutBack,
                child: Image.asset(
                  'images/LOGOAYD.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Animated App Name
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showText ? 1.0 : 0.0,
              child: const Text(
                'Tagtime Medicare',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB35750),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Animated Version
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showVersion ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: const Color(0xFFB35750).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: const Text(
                  'Version 1.0',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB35750),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}