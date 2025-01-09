import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/screens/custom_navbar.dart';
import 'package:tagtime_medicare/screens/history_page.dart';
import 'package:tagtime_medicare/screens/profile_page.dart'; 
import 'package:tagtime_medicare/screens/home_page_content.dart';
import 'package:tagtime_medicare/screens/summary_page.dart'; // Import HomePageContent

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
        // Fetch First Name from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        setState(() {
          firstName = userData['Name'] ?? 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        firstName = 'User';
        isLoading = false;
      });
    }
  }

  void onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePageContent(firstName: firstName), // แสดงข้อความ Hi, first name เฉพาะในหน้า Home
      SummaryPage(),
      HistoryPage(),
      ProfilePage(), // หน้า ProfilePage ไม่มี Hi, first name
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF4E0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: onNavBarTap,
      ),
    );
  }
}
