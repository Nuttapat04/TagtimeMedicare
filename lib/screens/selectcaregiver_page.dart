import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tagtime_medicare/screens/assign/assignrfid_page.dart';

class SelectCaregiverPage extends StatefulWidget {
  @override
  _SelectCaregiverPageState createState() => _SelectCaregiverPageState();
}

class _SelectCaregiverPageState extends State<SelectCaregiverPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> caregiverList = [];
  String? selectedCaregiver;

  @override
  void initState() {
    super.initState();
    fetchCaregivers();
  }

  Future<void> fetchCaregivers() async {
    final user = _auth.currentUser;
    if (user != null) {
      final caregiversSnapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Caregivers')
          .get();
      setState(() {
        caregiverList = caregiversSnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Select Caregiver',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: caregiverList.length,
              itemBuilder: (context, index) {
                final caregiver = caregiverList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      caregiver['Name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC76355),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact: ${caregiver['Contact']}'),
                        Text('Relationship: ${caregiver['Relationship']}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignRFIDPage(
                            assignType: 'Caregiver',
                            caregiverId: caregiver['id'],
                            caregiverName: caregiver['Name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}