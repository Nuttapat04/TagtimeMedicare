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
  bool _showWarning = false;
  bool _showButton = false;
  double _logoSize = 150;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });

    _startAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    // เริ่มแสดง Logo ด้วย fade in
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showLogo = true);

    // ทำให้ Logo ขยายขึ้น
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _logoSize = 200);

    // แสดงชื่อแอพ
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showText = true);

    // แสดงเวอร์ชัน
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showVersion = true);

    // แสดงคำเตือน
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showWarning = true);

    // แสดงปุ่ม
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _showButton = true);
      _pulseController.forward();
    }
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
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
                        height: _logoSize * 0.72,
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
            ),
            
            // Warning Section at bottom
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showWarning ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB35750),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB35750).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: const Color(0xFFB35750),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'คำเตือนสำคัญ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB35750),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• แอปพลิเคชันนี้เป็นเพียงเครื่องมือช่วยเตือนการรับประทานยาเท่านั้น',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• กรุณาปรึกษาแพทย์หรือเภสัชกรสำหรับข้อมูลการใช้ยาที่ถูกต้อง',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue Button with Arrow and Pulse Animation
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showButton ? 1.0 : 0.0,
              child: Column(
                children: [
                  // Animated Arrow
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 10 * (1 - _pulseController.value)),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 40,
                          color: const Color(0xFFB35750),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Pulsing Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: ElevatedButton(
                            onPressed: _showButton ? _navigateToNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB35750),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                              shadowColor: const Color(0xFFB35750).withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'แตะที่นี่เพื่อดำเนินการต่อ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}