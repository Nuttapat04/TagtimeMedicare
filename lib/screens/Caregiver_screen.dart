import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaregiverPage extends StatefulWidget {
  @override
  _CaregiverPageState createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<QueryDocumentSnapshot> caregiverList = [];

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
        caregiverList = caregiversSnapshot.docs;
      });
    }
  }

  Future<void> addCaregiver(String name, String contact, String relationship) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (caregiverList.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can add only up to 3 caregivers')),
        );
        return;
      }
      await _firestore.collection('Users').doc(user.uid).collection('Caregivers').add({
        'Name': name,
        'Contact': contact,
        'Relationship': relationship,
        'User_id': user.uid,
      });
      fetchCaregivers();
    }
  }

  Future<void> updateCaregiver(String docId, String name, String contact, String relationship) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Caregivers')
          .doc(docId)
          .update({
        'Name': name,
        'Contact': contact,
        'Relationship': relationship,
      });
      fetchCaregivers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caregiver updated successfully'),
          backgroundColor: Color(0xFFC76355),
        ),
      );
    }
  }

  Future<void> deleteCaregiver(String docId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Caregivers')
          .doc(docId)
          .delete();
      fetchCaregivers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caregiver deleted successfully'),
          backgroundColor: Color(0xFFC76355),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF4E0),
      appBar: AppBar(
        title: const Text(
          'Caregivers',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFEF4E0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              if (caregiverList.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Color(0xFFC76355).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No caregivers added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFC76355).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: caregiverList.length,
                  itemBuilder: (context, index) {
                    final caregiver = caregiverList[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caregiver['Name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC76355),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        caregiver['Contact'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        caregiver['Relationship'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFFC76355),
                              ),
                              onPressed: () => _showEditCaregiverDialog(
                                caregiverList[index].id,
                                caregiver,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _showDeleteCaregiverDialog(caregiverList[index].id),
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
          if (caregiverList.length < 3)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 60,
                  width: 60,
                  child: FloatingActionButton(
                    onPressed: () => _showAddCaregiverDialog(),
                    backgroundColor: const Color(0xFFC76355),
                    elevation: 4,
                    child: const Icon(
                      Icons.add,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddCaregiverDialog() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Add Caregiver',
            style: TextStyle(
              color: Color(0xFFC76355),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    contactController.text.isNotEmpty &&
                    relationshipController.text.isNotEmpty) {
                  addCaregiver(
                    nameController.text,
                    contactController.text,
                    relationshipController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Color(0xFFC76355),
                    ),
                  );
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFFC76355),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // เพิ่มฟังก์ชันแสดง dialog แก้ไขข้อมูล
  void _showEditCaregiverDialog(String docId, Map<String, dynamic> caregiver) {
    final nameController = TextEditingController(text: caregiver['Name']);
    final contactController = TextEditingController(text: caregiver['Contact']);
    final relationshipController = TextEditingController(text: caregiver['Relationship']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Edit Caregiver',
            style: TextStyle(
              color: Color(0xFFC76355),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    labelStyle: TextStyle(color: Color(0xFFC76355)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC76355)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    contactController.text.isNotEmpty &&
                    relationshipController.text.isNotEmpty) {
                  updateCaregiver(
                    docId,
                    nameController.text,
                    contactController.text,
                    relationshipController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Color(0xFFC76355),
                    ),
                  );
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFFC76355),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // เพิ่มฟังก์ชันแสดง dialog ลบข้อมูล
  void _showDeleteCaregiverDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Delete Caregiver',
            style: TextStyle(
              color: Color(0xFFC76355),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this caregiver?',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                deleteCaregiver(docId);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
