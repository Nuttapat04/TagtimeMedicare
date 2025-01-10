import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // ถ้าผู้ใช้ล็อกอินอยู่แล้ว -> ไปที่หน้า Home
      Navigator.pushReplacementNamed(context, '/splash'); // หรือ '/home'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0), // พื้นหลังสีเดียวกับ Splash Screen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // เพิ่มระยะขอบด้านข้าง
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 20), // เพิ่มระยะห่างจากขอบด้านบน
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'images/LOGOAYD.png', // โลโก้
                          height: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFFD84315),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Tagtime Medicare',
                          style: TextStyle(
                            fontSize: 32,
                            color: Color(0xFFD84315),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // ทำให้รูปอยู่ตรงกลาง
                  children: [
                    Image.asset(
                      'images/welcome4.png', // รูปพื้นหลังใหม่
                      height: 550, // ปรับขนาดรูป
                      width: MediaQuery.of(context).size.width, // ปรับให้เต็มหน้าจอ
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // ลดช่องว่างระหว่างรูปกับปุ่ม
              Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD84315), // สีปุ่ม Log in
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        elevation: 5, // เพิ่มเงาให้ปุ่ม
                        shadowColor: Colors.grey.withOpacity(0.5), // สีเงา
                        padding: const EdgeInsets.symmetric(
                            horizontal: 150, vertical: 15),
                      ),
                      child: const Text(
                        'Log in',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // ลดช่องว่างระหว่างปุ่ม
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF4E0),
                        side: const BorderSide(color: Color(0xFFD84315)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        elevation: 5, // เพิ่มเงาให้ปุ่ม
                        shadowColor: Colors.grey.withOpacity(0.5), // สีเงา
                        padding: const EdgeInsets.symmetric(
                            horizontal: 145, vertical: 15),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(fontSize: 18, color: Color(0xFFD84315)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
