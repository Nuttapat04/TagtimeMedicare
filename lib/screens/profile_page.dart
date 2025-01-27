import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String firstName = '';
  String lastName = '';
  String email = '';
  String photoURL = '';
  String loginType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('Users').doc(user.uid).get();

        setState(() {
          firstName = userData['Name'] ?? 'User';  // Changed from 'name'
          lastName = userData['Surname'] ?? '';    // Changed from 'surname'
          email = userData['Email'] ?? '';         // Added Email field
          photoURL = userData['photoURL'] ?? '';   // Kept as is, matches database
          loginType = userData['loginType'] ?? 'email';
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

Future<void> _changeProfileImage() async {
  if (loginType != 'email') return;

  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) return;

    // Check if there is a current photoURL and try to delete it
    if (photoURL.isNotEmpty && photoURL.contains('firebase')) {
      try {
        final oldImageRef = FirebaseStorage.instance.refFromURL(photoURL);
        await oldImageRef.delete();  // Attempt to delete old image if it exists
      } catch (e) {
        print('Error deleting old image: $e'); // Handle the error if the image is not found
      }
    }

    // Upload new image
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(File(image.path));
    final url = await ref.getDownloadURL();

    // Update URL in Firestore
    await _firestore
        .collection('Users')
        .doc(user.uid)
        .update({'photoURL': url});

    setState(() {
      photoURL = url;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile picture updated successfully')),
    );
  } catch (e) {
    print('Error updating profile image: $e');
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update profile picture')),
    );
  }
}

  Widget buildProfileImage() {
    Widget profileWidget;

    if (photoURL.isNotEmpty) {
      profileWidget = CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(photoURL),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading profile image: $exception');
          setState(() {
            photoURL = '';
          });
        },
      );
    } else {
      profileWidget = CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFFC76355),
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return loginType == 'email'
        ? GestureDetector(
            onTap: _changeProfileImage,
            child: Stack(
              children: [
                profileWidget,
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFC76355),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          )
        : profileWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF4E0),
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFF4E0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC76355)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Profile Section
                  Column(
                    children: [
                      buildProfileImage(),
                      const SizedBox(height: 16),
                      // Name display
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC76355),
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Menu Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        buildMenuTile(
                          icon: Icons.settings,
                          title: 'Edit Information',
                          onTap: () => Navigator.pushNamed(context, '/edit-information'),
                        ),
                        const Divider(height: 1),
                        buildMenuTile(
                          icon: Icons.support_agent,
                          title: 'Customer Support',
                          onTap: () => Navigator.pushNamed(context, '/customer-support'),
                        ),
                        const Divider(height: 1),
                        buildMenuTile(
                          icon: Icons.accessibility_new,
                          title: 'Caregiver',
                          onTap: () => Navigator.pushNamed(context, '/caregiver'),
                        ),
                        const Divider(height: 1),
                        buildMenuTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () => showLogoutConfirmation(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFC76355)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/welcome');
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}