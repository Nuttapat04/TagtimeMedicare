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
          throw Exception('Username is already taken');
        }

        // Check age requirement
        if (selectedDate == null || !isOver14Years(selectedDate!)) {
          throw Exception('You must be at least 14 years old to register');
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
          SnackBar(content: Text('Registration Successful!')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error during registration: $e');
        String message = 'An error occurred during registration';

        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            message = 'This email is already registered';
          } else if (e.code == 'weak-password') {
            message = 'The password provided is too weak';
          } else if (e.code == 'invalid-email') {
            message = 'The email address is not valid';
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
          'Register',
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
                            value!.isEmpty ? 'Please enter a username' : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
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
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          final passwordRegex = RegExp(
                              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d]{8,}$');
                          if (!passwordRegex.hasMatch(value)) {
                            return 'Password must contain uppercase, lowercase and number';
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
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: nameController,
                        label: 'First Name',
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your first name'
                            : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: surnameController,
                        label: 'Last Name',
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your last name'
                            : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: phoneController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          final phoneRegex = RegExp(r'^0[0-9]{9}$');
                          if (!phoneRegex.hasMatch(value)) {
                            return 'Please enter a valid phone number';
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
                          'Register',
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
        helperText: 'At least 8 characters with uppercase, lowercase & number',
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
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)').hasMatch(value)) {
          return 'Include uppercase, lowercase & number';
        }
        // Check for common passwords
        if (['password123', 'qwerty123', '12345678']
            .contains(value.toLowerCase())) {
          return 'Please use a stronger password';
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
        helperText: 'Must be at least 14 years old',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your date of birth';
        }
        if (selectedDate == null || !isOver14Years(selectedDate!)) {
          return 'You must be at least 14 years old';
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
          errorFormatText: 'Enter valid date',
          errorInvalidText: 'Enter date in valid range',
        );
        if (picked != null) {
          if (!isOver14Years(picked)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You must be at least 14 years old')),
            );
            return;
          }
          onDatePicked(picked);
        }
      },
    );
  }
}
