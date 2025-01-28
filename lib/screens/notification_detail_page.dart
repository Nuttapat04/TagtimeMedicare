
import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String payload; // ข้อมูลที่จะรับมาจาก notification

  const NotificationDetailPage({
    Key? key,
    required this.payload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Detail'),
      ),
      body: Center(
        child: Text('This is detail of: $payload'),
      ),
    );
  }
}
