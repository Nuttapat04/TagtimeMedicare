import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF4E0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFEF4E0),
        elevation: 0,
        title: Text(
          'History',
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text('ยังไม่ทำ', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
