import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF4E0),
      body: Column(
        children: [
          // โลโก้และข้อความ
          Column(
            children: [
              Image.asset(
                'images/LOGOAYD.png', // เส้นทางของโลโก้
                height: 70, // ขนาดความสูงของโลโก้
              ),
              SizedBox(height: 0), // ระยะห่างระหว่างโลโก้กับข้อความ
              Text(
                "Test",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF763355),
                ),
              ),
            ],
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Color(0xFFFFF4E0),
              appBar: AppBar(
                backgroundColor: Color(0xFFFFF4E0),
                elevation: 0,
                centerTitle: true,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Color(0xFF763355),
                  labelColor: Color(0xFF763355),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'List'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildListPage(),
                  _buildHistoryPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Medications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final medications = snapshot.data!.docs;

        if (medications.isEmpty) {
          return Center(
            child: Text(
              'ไม่มีรายการยา',
              style: TextStyle(fontSize: 24),
            ),
          );
        }

        return ListView.builder(
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final med = medications[index].data() as Map<String, dynamic>;
            final name = med['M_name'] ?? 'ไม่มีชื่อยา';
            final time = med['Notification_times'] ?? [];

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'เวลาแจ้งเตือน: ${time is List ? time.join(', ') : 'ไม่ระบุ'}',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Medications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final medications = snapshot.data!.docs;

        if (medications.isEmpty) {
          return Center(
            child: Text(
              'ยังไม่มีประวัติ',
              style: TextStyle(fontSize: 24),
            ),
          );
        }

        Map<String, List<Map<String, dynamic>>> groupedMedications = {};
        for (var doc in medications) {
          final med = doc.data() as Map<String, dynamic>;

          String dateKey;
          try {
            dateKey = med['Start_date'] is Timestamp
                ? (med['Start_date'] as Timestamp).toDate().toString().split(' ')[0]
                : DateTime.parse(med['Start_date']).toString().split(' ')[0];
          } catch (e) {
            dateKey = 'Invalid Date';
          }

          if (dateKey != 'Invalid Date') {
            if (groupedMedications[dateKey] == null) {
              groupedMedications[dateKey] = [];
            }
            groupedMedications[dateKey]!.add(med);
          }
        }

        List<String> sortedDates = groupedMedications.keys.toList()
          ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            String date = sortedDates[index];
            List<Map<String, dynamic>> meds = groupedMedications[date]!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(date)),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF763355),
                    ),
                  ),
                  SizedBox(height: 8),
                  ...meds.map((med) {
                    final name = med['M_name'] ?? 'ไม่มีชื่อยา';
                    final frequency = med['Frequency'] ?? 'ไม่ระบุ';
                    final notificationTimes = med['Notification_times'] ?? [];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('จำนวนครั้ง: $frequency'),
                            Text(
                              'เวลาแจ้งเตือน: ${notificationTimes is List ? notificationTimes.join(', ') : 'ไม่ระบุ'}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 
