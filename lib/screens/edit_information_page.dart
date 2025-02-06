import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditInformationPage extends StatefulWidget {
  @override
  _EditInformationPageState createState() => _EditInformationPageState();
}

class _EditInformationPageState extends State<EditInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();

  String email = '';
  bool isLoading = true;
  String loginType = '';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        setState(() {
          nameController.text = userData['Name'] ?? '';
          surnameController.text = userData['Surname'] ?? '';
          phoneController.text = userData['Phone'] ?? '';
          symptomsController.text =
              userData['symptoms'] ?? ''; // เพิ่มบรรทัดนี้
          email = user.email ?? '';
          loginType = userData['loginType'] ?? '';

          // Handle date of birth
          if (userData['Date_of_Birth'] != null) {
            if (userData['Date_of_Birth'] is Timestamp) {
              selectedDate = (userData['Date_of_Birth'] as Timestamp).toDate();
              dateController.text = formatDate(selectedDate!);
            }
          }

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

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = formatDate(pickedDate);
      });
    }
  }

  Future<void> updateUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;

        if (user != null) {
          Map<String, dynamic> updateData = {
            'Name': nameController.text.trim(),
            'Surname': surnameController.text.trim(),
            'Phone': phoneController.text.trim(),
            'symptoms': symptomsController.text.trim(), // เพิ่มบรรทัดนี้
          };

          // Only update Date_of_Birth if a date was selected
          if (selectedDate != null) {
            updateData['Date_of_Birth'] = Timestamp.fromDate(selectedDate!);
          }

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .update(updateData);

          if (passwordController.text.isNotEmpty) {
            await user.updatePassword(passwordController.text.trim());
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Information updated successfully!')),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        print('Error updating user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update information')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF4E0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC76355)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แก้ไขข้อมูล',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFF4E0),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC76355)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            setState(() {
                              passwordController.text = '';
                            });
                          },
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly:
                          true, // Always readonly since we use date picker
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'อาการเจ็บป่วย (ไม่บังคับ)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC76355),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: symptomsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'กรุณาระบุอาการเจ็บป่วยของท่าน (ถ้ามี)',
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text(
                              'ข้อมูลนี้จะช่วยให้เราสามารถให้บริการที่เหมาะสมกับท่านได้ดียิ่งขึ้น',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC76355),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
