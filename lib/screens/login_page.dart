import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> handleRoleBasedNavigation(String uid) async {
    final docRef = _firestore.collection('Users').doc(uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final role = docSnapshot.data()?['Role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminpage');
      } else {
        Navigator.pushReplacementNamed(context, '/splash');
      }
    }
  }

  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final docRef =
            _firestore.collection('Users').doc(userCredential.user!.uid);
        await docRef.update({
          'Last_login': FieldValue.serverTimestamp(),
        });

        await handleRoleBasedNavigation(userCredential.user!.uid);
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else {
          message = 'Please check your email or password.';
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final docRef = _firestore.collection('Users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          var names = user.displayName?.split(' ') ?? [''];
          var firstName = names.first;
          var surname = names.length > 1 ? names.sublist(1).join(' ') : '';

          await docRef.set({
            'Email': user.email ?? '',
            'Name': firstName,
            'Surname': surname,
            'Username': (user.email?.split('@')[0] ?? '').toLowerCase(),
            'Phone': user.phoneNumber ?? '',
            'Role': 'user',
            'Date_of_Birth': null,
            'Created_at': FieldValue.serverTimestamp(),
            'loginType': 'google',
            'photoURL': user.photoURL ?? '',
            'Last_login': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacementNamed(context, '/splash');
        } else {
          await docRef.update({
            'Last_login': FieldValue.serverTimestamp(),
            'photoURL': user.photoURL ?? '',
          });

          await handleRoleBasedNavigation(user.uid);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${user.displayName}!')),
        );
      }
    } catch (e) {
      print('Error during Google sign in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4E0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC76355),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  decoration: buildInputDecoration('Email', Icons.email),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: buildPasswordDecoration(),
                  obscureText: !_isPasswordVisible,
                  validator: validatePassword,
                ),
                const SizedBox(height: 8),
                buildForgotPasswordButton(),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator(color: Color(0xFFC76355))
                else
                  Column(
                    children: [
                      buildLoginButton(),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                              endIndent: 8,
                            ),
                          ),
                          Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                              indent: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildGoogleSignInButton(),
                      const SizedBox(height: 16),
                      buildRegisterButton(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.brown),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }

  InputDecoration buildPasswordDecoration() {
    return InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock, color: Colors.brown),
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.brown[800],
        ),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }

  Widget buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/forget-password'),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(color: Color(0xFFC76355)),
        ),
      ),
    );
  }

  Widget buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC76355),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: const Text(
          'Login with Email',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton.icon(
        icon: Image.asset('images/google_logo.png', height: 24),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFFC76355),
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFC76355)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }

  Widget buildRegisterButton() {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/register'),
      child: const Text(
        'Don\'t have an account? Register here',
        style: TextStyle(color: Color(0xFFC76355)),
      ),
    );
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}
