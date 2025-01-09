import 'package:flutter/material.dart';

class HomePageContent extends StatelessWidget {
  final String firstName; // รับค่า First Name

  const HomePageContent({Key? key, required this.firstName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hi, $firstName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC76355),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to the Home Page!',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
