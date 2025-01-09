import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF4E0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFEF4E0),
        elevation: 0,
        title: Text(
          'Summary',
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  SummaryCard(
                    title: 'Medication 1',
                    details: 'Details about Medication 1...',
                  ),
                  SummaryCard(
                    title: 'Medication 2',
                    details: 'Details about Medication 2...',
                  ),
                  SummaryCard(
                    title: 'Medication 3',
                    details: 'Details about Medication 3...',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String details;

  const SummaryCard({required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),
            SizedBox(height: 5),
            Text(
              details,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
