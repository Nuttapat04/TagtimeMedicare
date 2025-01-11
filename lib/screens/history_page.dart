import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  HistoryPage({required this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int displayCount = 10;

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
      backgroundColor: const Color(0xFFFEF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF4E0),
        title: const Text(
          "Your Medication History",
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFC76355),
            labelColor: const Color(0xFFC76355),
            unselectedLabelColor: Colors.grey,
            labelStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'History List'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListPage(),
                _buildHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Medications')
          .where('user_id', isEqualTo: widget.userId)
          .orderBy('Updated_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final medications = snapshot.data!.docs;

        if (medications.isEmpty) {
          return const Center(
            child: Text(
              'No medications found',
              style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
            ),
          );
        }

        final itemsToShow = medications.length > displayCount
            ? displayCount
            : medications.length;

        // สร้าง list ของ widgets ที่จะแสดง
        List<Widget> items = [];

        // เพิ่มรายการยาเข้าไปใน list
        for (var i = 0; i < itemsToShow; i++) {
          final med = medications[i].data() as Map<String, dynamic>;
          final name = med['M_name'] ?? 'No name';
          final time = med['Notification_times'] ?? [];
          final startDate = med['Start_date'] is Timestamp
              ? (med['Start_date'] as Timestamp).toDate()
              : DateTime.now();
          final endDate = med['End_date'] is Timestamp
              ? (med['End_date'] as Timestamp).toDate()
              : DateTime.now();
          final frequency = med['Frequency'] ?? '1 time/day';
          final assignedBy = med['Assigned_by'] ?? 'Unknown';

          final formattedStartDate = DateFormat('dd/MM/yyyy').format(startDate);
          final formattedEndDate = DateFormat('dd/MM/yyyy').format(endDate);

          items.add(
            Card(
              margin: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC76355),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Frequency: $frequency',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFFC76355),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Times: ${time.join(', ')}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dates: $formattedStartDate to $formattedEndDate',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Assigned by: ${assignedBy}${med['Caregiver_name'] != null && assignedBy == 'Caregiver' ? ' (${med['Caregiver_name']})' : ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // เพิ่มปุ่ม See More ถ้ายังมีรายการเหลือ
        if (medications.length > displayCount) {
          items.add(
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC76355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    displayCount += 10;
                  });
                },
                child: const Text(
                  'See More',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }

        // สร้าง ListView แบบไม่ scrollable
        return ListView(
          children: items,
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Medication_history')
          .where('User_id', isEqualTo: widget.userId)
          .orderBy('Intake_time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!.docs;

        if (history.isEmpty) {
          return const Center(
            child: Text(
              'No medication history found',
              style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
            ),
          );
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index].data() as Map<String, dynamic>;
            final status = entry['Status'] ?? 'Missed';
            final time = (entry['Intake_time'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $status',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC76355),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Time: ${DateFormat('hh:mm a on dd/MM/yyyy').format(time)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFFC76355),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
