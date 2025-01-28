import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/screens/custom_navbar.dart';
import 'package:tagtime_medicare/screens/history_page.dart';
import 'package:tagtime_medicare/screens/profile_page.dart'; 
import 'package:tagtime_medicare/screens/RFID_screen.dart';
import 'package:tagtime_medicare/screens/summary_page.dart';
import 'package:tagtime_medicare/screens/medication_service.dart'; // Import MedicationService

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String firstName = '';
  String userId = ''; // User ID ของผู้ใช้ปัจจุบัน
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // ดึงข้อมูลผู้ใช้
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            firstName = userData['Name'] ?? 'User';
            userId = user.uid; // กำหนด userId
            isLoading = false;
          });
          // เรียก setupNotifications หลังได้ userId
          setupNotifications();
        } else {
          setState(() {
            firstName = 'Guest';
            userId = '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        firstName = 'User';
        userId = '';
        isLoading = false;
      });
    }
  }

  Future<void> setupNotifications() async {
    if (userId.isNotEmpty) {
      print('Setting up notifications for userId: $userId...');
      final medicationService = MedicationService();
      await medicationService.fetchAndScheduleNotifications(userId);
      print('Notifications have been set up successfully for $userId!');
    } else {
      print('No userId available. Skipping notifications setup.');
    }
  }

  void onRFIDDetected() {
    print('RFID detected!');
  }

  void onAssignPressed() {
    print('Assign button pressed!');
  }

  void onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      RFIDPage(
        onRFIDDetected: onRFIDDetected,
        onAssignPressed: onAssignPressed,
        firstName: firstName,
      ),
      SummaryPage(userId: userId,),
      HistoryPage(userId: userId), // ส่ง userId ไปยัง HistoryPage
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF4E0),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user data...'),
                ],
              ),
            )
          : _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: onNavBarTap,
      ),
    );
  }
}