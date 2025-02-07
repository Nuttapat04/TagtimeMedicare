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
    with TickerProviderStateMixin {
  late TabController _tabController;
  int displayCount = 10; // สำหรับ List tab
  int _displayDays = 3; // เริ่มต้นแสดง 3 วัน สำหรับ History tab
  static const int _maxDays = 10; // จำนวนวันสูงสุดที่แสดงได้

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
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFEF4E0),
        title: const Text(
          "ประวัติยาของคุณ",
          style: TextStyle(color: Color(0xFFC76355),
          fontWeight: FontWeight.bold,),
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
              Tab(text: 'รายการยา'),
              Tab(text: 'ประวัติ'),
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
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Refresh data
      },
      child: StreamBuilder<QuerySnapshot>(
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
                'ไม่พบข้อมูลยา',
                style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
              ),
            );
          }

          final itemsToShow = medications.length > displayCount
              ? displayCount
              : medications.length;

          return ListView.builder(
            itemCount:
                itemsToShow + (medications.length > displayCount ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == itemsToShow) {
                return Padding(
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
                      'ดูเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }

              final med = medications[index].data() as Map<String, dynamic>;
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

              final formattedStartDate =
                  DateFormat('dd/MM/yyyy').format(startDate);
              final formattedEndDate = DateFormat('dd/MM/yyyy').format(endDate);

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                              'จำนวณครั้ง: $frequency',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFFC76355),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'เวลา: ${time.join(', ')}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'วันที่: $formattedStartDate ถึง $formattedEndDate',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'จ่ายยาโดย: ${assignedBy}${med['Caregiver_name'] != null && assignedBy == 'Caregiver' ? ' (${med['Caregiver_name']})' : ''}',
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _displayDays = 3; // reset กลับไปแสดง 3 วันเมื่อ refresh
        });
      },
      child: StreamBuilder<QuerySnapshot>(
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
                'ไม่พบประวัติการใช้ยา',
                style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
              ),
            );
          }

          DateTime now = DateTime.now();
          DateTime cutoffDate = now.subtract(Duration(days: _displayDays));

          return FutureBuilder<Map<String, String>>(
            future: _fetchMedicationNames(history),
            builder: (context, medSnapshot) {
              if (!medSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final medNames = medSnapshot.data!;
              Map<String, Map<String, List<Map<String, dynamic>>>>
                  groupedHistory = {};

              // กรองข้อมูลตามจำนวนวันที่ต้องการแสดง
              for (var doc in history) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['Intake_time'] as Timestamp).toDate();

                // ข้ามข้อมูลที่เก่าเกินกว่าจำนวนวันที่ต้องการแสดง
                if (timestamp.isBefore(cutoffDate)) continue;

                final dateKey = DateFormat('dd/MM/yyyy').format(timestamp);
                final medId = data['Medication_id'] ?? 'Unknown';
                final medName = medNames[medId] ?? 'Unknown Medication';
                final status = data['Status'] ?? 'Missed';

                final entry = {
                  'Scheduled_time': data['Scheduled_time'] ?? 'Unknown',
                  'Status': status,
                  'Time': timestamp,
                };

                groupedHistory.putIfAbsent(dateKey, () => {});
                groupedHistory[dateKey]!.putIfAbsent(medName, () => []);
                groupedHistory[dateKey]![medName]!.add(entry);
              }

              // คำนวณว่ามีข้อมูลเกิน _displayDays หรือไม่
              bool hasMoreDays = history.any((doc) {
                final timestamp = (doc.data()
                    as Map<String, dynamic>)['Intake_time'] as Timestamp;
                return timestamp.toDate().isBefore(cutoffDate) &&
                    timestamp
                        .toDate()
                        .isAfter(now.subtract(Duration(days: _maxDays)));
              });

              return ListView(
                children: [
                  ...groupedHistory.entries.map((dateEntry) {
                    final date = dateEntry.key;
                    final medicationsByName = dateEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC76355),
                            ),
                          ),
                        ),
                        ...medicationsByName.entries.map((medEntry) {
                          final medName = medEntry.key;
                          final times = medEntry.value;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC76355),
                                    ),
                                  ),
                                  ...times
                                      .map((med) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  med['Scheduled_time'],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: med['Status'] ==
                                                            'On Time'
                                                        ? Colors.green
                                                        : Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    med['Status'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),

                  // แสดงปุ่ม See More ถ้ายังมีข้อมูลที่เหลือและยังไม่ถึง _maxDays
                  if (hasMoreDays && _displayDays < _maxDays)
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
                            _displayDays =
                                _displayDays + 3; // เพิ่มครั้งละ 3 วัน
                            if (_displayDays > _maxDays) {
                              _displayDays = _maxDays;
                            }
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ ดึง `M_name` จาก `Medications` โดยใช้ `Medication_id`
  Future<Map<String, String>> _fetchMedicationNames(
      List<QueryDocumentSnapshot> history) async {
    Map<String, String> medNames = {};
    Set<String> medIds = {};

    for (var doc in history) {
      final data = doc.data() as Map<String, dynamic>;
      final medId = data['Medication_id'];
      if (medId != null) {
        medIds.add(medId);
      }
    }

    if (medIds.isEmpty) return medNames;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where(FieldPath.documentId, whereIn: medIds.toList())
          .get();

      for (var doc in snapshot.docs) {
        medNames[doc.id] = doc['M_name'] ?? 'Unknown Medication';
      }
    } catch (e) {
      print("🔥 Error fetching medication names: $e");
    }

    return medNames;
  }
}
