import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String email = '';
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
        // ดึงข้อมูลผู้ใช้จาก Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        setState(() {
          firstName = userData['Name'] ?? 'User';
          lastName = userData['Surname'] ?? ''; // ดึงข้อมูล Surname จาก Firestore
          email = user.email ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF4E0),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFF4E0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFC76355),
                    child: Text(
                      firstName.isNotEmpty
                          ? firstName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC76355),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Color(0xFFC76355)),
                    title: const Text(
                      'Edit Informations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.grey),
                    onTap: () {
                      Navigator.pushNamed(context, '/edit-information');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent,
                        color: Color(0xFFC76355)),
                    title: const Text(
                      'Customer Support',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.grey),
                    onTap: () {
                      Navigator.pushNamed(context, '/customer-support');
                    },
                  ),
                  // เพิ่ม ListTile สำหรับ Caregiver
                  ListTile(
                    leading: const Icon(Icons.accessibility_new,
                        color: Color(0xFFC76355)),
                    title: const Text(
                      'Caregiver',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.grey),
                    onTap: () {
                      Navigator.pushNamed(context, '/caregiver');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFC76355)),
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.grey),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
