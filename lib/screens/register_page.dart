import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController symptomsController = TextEditingController();

  DateTime? selectedDate;

  File? _imageFile; // สำหรับเก็บรูปภาพที่เลือก
  bool isLoading = false;
  bool _isPasswordHidden = true;

  bool isOver14Years(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 14;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('Users')
        .where('Username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return result.docs.isEmpty;
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Check username availability first
        final isAvailable =
            await isUsernameAvailable(usernameController.text.trim());
        if (!isAvailable) {
          throw Exception('Username นี้ถูกใช้งานไปแล้ว');
        }

        // Check age requirement
        if (selectedDate == null || !isOver14Years(selectedDate!)) {
          throw Exception('คุณต้องมีอายุอย่างน้อย 14 ปีขึ้นไป');
        }

        // Create user account in Authentication first
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Get the user ID
        final uid = userCredential.user!.uid;

        // Upload profile image if exists
        String? photoURL;
        if (_imageFile != null) {
          photoURL = await _uploadImage();
        }

        // Create user data object
        final userData = {
          'Username': usernameController.text.trim().toLowerCase(),
          'Email': emailController.text.trim().toLowerCase(),
          'Name': nameController.text.trim(),
          'Surname': surnameController.text.trim(),
          'Phone': phoneController.text.trim(),
          'Date_of_Birth': Timestamp.fromDate(selectedDate!),
          'Created_at': FieldValue.serverTimestamp(),
          'Last_login': FieldValue.serverTimestamp(),
          'Role': 'user',
          'photoURL': photoURL ?? '',
          'loginType': 'email',
          'isActive': true,
          'deviceTokens': [],
          'symptoms': symptomsController.text.trim(), // เพิ่มข้อมูลอาการ
        };

        // Add user data to Firestore
        await _firestore.collection('Users').doc(uid).set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error during registration: $e');
        String message = 'An error occurred during registration';

        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            message = 'อีเมลนี้ถูกใช้งานไปแล้ว';
          } else if (e.code == 'weak-password') {
            message = 'รหัสผ่านอ่อนแอเกินไป';
          } else if (e.code == 'invalid-email') {
            message = 'อีเมลไม่ถูกต้อง';
          }
        } else if (e is Exception) {
          message = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        title: Text(
          'สมัครสมาชิก',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: const Color(0xFFC76355),
          ),
        ),
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        iconTheme: IconThemeData(color: const Color(0xFFC76355)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey[800],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildTextFormField(
                        controller: usernameController,
                        label: 'Username',
                        validator: (value) =>
                            value!.isEmpty ? 'กรุณากรอก Username' : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'กรุณากรอกอีเมลให้ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildPasswordFormField(
                        controller: passwordController,
                        label: 'Password',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (value.length < 8) {
                            return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                          }
                          final passwordRegex = RegExp(
                              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d]{8,}$');
                          if (!passwordRegex.hasMatch(value)) {
                            return 'รหัสผ่านต้องมีอย่างน้อย ตัวพิมพ์ใหญ่, ตัวพิมพ์เล็กและ ตัวเลข';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildPasswordFormField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        validator: (value) {
                          if (value != passwordController.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: nameController,
                        label: 'First Name',
                        validator: (value) => value!.isEmpty
                            ? 'กรุณากรอกชื่อ'
                            : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: surnameController,
                        label: 'Last Name',
                        validator: (value) => value!.isEmpty
                            ? 'กรุณากรอกนามสกุล'
                            : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: phoneController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกเบอร์โทร';
                          }
                          final phoneRegex = RegExp(r'^0[0-9]{9}$');
                          if (!phoneRegex.hasMatch(value)) {
                            return 'กรุณากรอกเบอร์โทรที่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildDatePickerFormField(
                        controller: dateController,
                        label: 'Date of Birth',
                        onDatePicked: (picked) {
                          setState(() {
                            selectedDate = picked;
                            dateController.text =
                                "${picked.toLocal().year}-${picked.toLocal().month.toString().padLeft(2, '0')}-${picked.toLocal().day.toString().padLeft(2, '0')}";
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      buildSymptomsField(), // เพิ่มฟิลด์อาการตรงนี้
                      SizedBox(height: 24), // เพิ่มระยะห่างก่อนปุ่ม Register
                      ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC76355),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildSymptomsField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'อาการเจ็บป่วย (ไม่บังคับ)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC76355),
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextFormField(
              controller: symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'กรุณาระบุอาการเจ็บป่วยของท่าน (ถ้ามี)',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
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
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFC76355),
        ),
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _isPasswordHidden,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFC76355),
        ),
        border: OutlineInputBorder(),
        helperText: 'รหัสผ่านต้องมีอย่างน้อย ตัวพิมพ์ใหญ่, ตัวพิมพ์เล็กและ ตัวเลข',
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFC76355),
          ),
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอกรหัสผ่าน';
        }
        if (value.length < 8) {
          return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
        }
        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)').hasMatch(value)) {
          return 'รหัสผ่านต้องมีอย่างน้อย ตัวพิมพ์ใหญ่, ตัวพิมพ์เล็กและ ตัวเลข';
        }
        // Check for common passwords
        if (['password123', 'qwerty123', '12345678']
            .contains(value.toLowerCase())) {
          return 'รหัสผ่านอ่อนแอเกินไป';
        }
        return null;
      },
    );
  }

  Widget buildDatePickerFormField({
    required TextEditingController controller,
    required String label,
    required Function(DateTime) onDatePicked,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFC76355),
        ),
        border: OutlineInputBorder(),
        helperText: 'คุณต้องมีอายุอย่างน้อย 14 ปีขึ้นไป',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'โปรดเลือกวันเกิดของคุณ';
        }
        if (selectedDate == null || !isOver14Years(selectedDate!)) {
          return 'คุณต้องมีอายุอย่างน้อย 14 ปีขึ้นไป';
        }
        return null;
      },
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(Duration(days: 14 * 365)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: 'Select Date of Birth',
          errorFormatText: 'กรุณากรอกวันเกิดให้ถูกต้อง',
          errorInvalidText: 'กรุณากรอกวันเกิดให้ถูกต้อง',
        );
        if (picked != null) {
          if (!isOver14Years(picked)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('คุณต้องมีอายุอย่างน้อย 14 ปีขึ้นไป')),
            );
            return;
          }
          onDatePicked(picked);
        }
      },
    );
  }
}
