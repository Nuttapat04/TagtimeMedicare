import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime? selectedDate;

  bool isLoading = false;
  bool _isPasswordHidden = true;

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        int age = DateTime.now().year - selectedDate!.year;
        if (DateTime.now().month < selectedDate!.month ||
            (DateTime.now().month == selectedDate!.month &&
                DateTime.now().day < selectedDate!.day)) {
          age--;
        }

        // ตรวจสอบ Username และ Email ว่าซ้ำหรือไม่
        final existingUser = await _firestore
            .collection('Users')
            .where('Username', isEqualTo: usernameController.text.trim())
            .get();
        if (existingUser.docs.isNotEmpty) {
          throw Exception('Username is already taken');
        }

        final existingEmail = await _auth.fetchSignInMethodsForEmail(emailController.text.trim());
        if (existingEmail.isNotEmpty) {
          throw Exception('This email is already registered');
        }

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await _firestore.collection('Users').doc(userCredential.user!.uid).set({
          'Username': usernameController.text.trim(),
          'Email': emailController.text.trim(),
          'Name': nameController.text.trim(),
          'Surname': surnameController.text.trim(),
          'Phone': phoneController.text.trim(),
          'Date_of_Birth': selectedDate?.toIso8601String(),
          'Age': age,
          'Created_at': FieldValue.serverTimestamp(),
          'Role': 'user',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      backgroundColor: const Color(0xFFFFF8E1),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          final emailRegex =
                              RegExp(r'^[^@]+@[^@]+\.[^@]+');
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
                              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
                          if (!passwordRegex.hasMatch(value)) {
                            return 'Password must contain uppercase, lowercase, number, and special character';
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
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your first name' : null,
                      ),
                      SizedBox(height: 16),
                      buildTextFormField(
                        controller: surnameController,
                        label: 'Last Name',
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your last name' : null,
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
      validator: validator,
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
      ),
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDatePicked(picked);
        }
      },
    );
  }
}
