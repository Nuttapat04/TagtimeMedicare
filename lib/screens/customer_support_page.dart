import 'package:flutter/material.dart';

class CustomerSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF4E0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC76355)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Customer Support',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFF4E0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Tel. 099-999-9999',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFC76355),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Address: 1518 ถนน ​ประชา​ราษฎร์​1 แขวงวงศ์สว่าง เขตบางซื่อ กรุงเทพมหานคร 10800',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
