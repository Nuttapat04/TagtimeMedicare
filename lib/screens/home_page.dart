import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/screens/custom_navbar.dart';
import 'package:tagtime_medicare/screens/history_page.dart';
import 'package:tagtime_medicare/screens/profile_page.dart'; 
import 'package:tagtime_medicare/screens/RFID_screen.dart';
import 'package:tagtime_medicare/screens/summary_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String firstName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
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
            isLoading = false;
          });
        } else {
          setState(() {
            firstName = 'Guest';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        firstName = 'User';
        isLoading = false;
      });
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
      SummaryPage(),
      HistoryPage(),
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
