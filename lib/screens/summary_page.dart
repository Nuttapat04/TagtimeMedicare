import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryPage extends StatefulWidget {
  final String userId;

  SummaryPage({required this.userId});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int touchedIndex = -1;

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
          "Summary",
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC76355),
          labelColor: const Color(0xFFC76355),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Current Medicines'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListPage(),
          _buildSummaryPage(),
        ],
      ),
    );
  }

  Widget _buildListPage() {
  return RefreshIndicator(
    onRefresh: _refreshData, // ฟังก์ชันที่ใช้รีเฟรชข้อมูล
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
              'No medications found',
              style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
            ),
          );
        }

        List<DocumentSnapshot> filteredMedications = medications.where((med) {
          final timeStrings = med['Notification_times'] ?? [];
          final endDate = med['End_date'] is Timestamp
              ? (med['End_date'] as Timestamp).toDate()
              : DateTime.now();

          if (timeStrings.isNotEmpty) {
            final lastTimeString = timeStrings.last;
            final timeParts = lastTimeString.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            final lastNotificationTime = DateTime(
                endDate.year, endDate.month, endDate.day, hour, minute);

            return lastNotificationTime.isAfter(DateTime.now());
          }
          return false;
        }).toList();

        if (filteredMedications.isEmpty) {
          return const Center(
            child: Text(
              'No active medications',
              style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredMedications.length,
          itemBuilder: (context, index) {
            final med = filteredMedications[index].data() as Map<String, dynamic>;
            final name = med['M_name'] ?? 'No name';
            final time = med['Notification_times'] ?? [];
            final startDate = med['Start_date'] is Timestamp
                ? (med['Start_date'] as Timestamp).toDate()
                : DateTime.now();
            final endDate = med['End_date'] is Timestamp
                ? (med['End_date'] as Timestamp).toDate()
                : DateTime.now();
            final assignedBy = med['Assigned_by'] ?? 'Unknown';

            // เวลาปัจจุบัน
            final now = DateTime.now();

            Color statusColor = Colors.grey;
            String statusText = '';

            if (now.isBefore(startDate)) {
              // ยังไม่ถึง startDate
              final totalDays = endDate.difference(startDate).inDays;
              statusText = 'Total duration: $totalDays days';
              statusColor = Colors.orange;
            } else if (now.isAfter(endDate)) {
              // เกิน endDate
              statusText = 'Today';
              statusColor = Colors.red;
            } else {
              // อยู่ในช่วง startDate ถึง endDate
              final remainingDays = endDate.difference(now).inDays;
              final remainingHours = endDate.difference(now).inHours % 24;
              statusText = '$remainingDays days $remainingHours hours left';
              statusColor = Colors.green;
            }

            final formattedStartDate = DateFormat('dd/MM/yyyy').format(startDate);
            final formattedEndDate = DateFormat('dd/MM/yyyy').format(endDate);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC76355),
                                  ),
                                ),
                              ),
                              if (statusText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Frequency: ${med['Frequency']}',
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
                    assignedBy != 'Pharmacist'
                        ? Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 30, color: Color(0xFFC76355)),
                                onPressed: () => _showEditDialog(
                                    filteredMedications[index].id, med),
                              ),
                              const SizedBox(height: 50),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 30, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                    filteredMedications[index].id),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 30, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                    filteredMedications[index].id),
                              ),
                            ],
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

Future<void> _refreshData() async {
  // เพิ่มฟังก์ชันนี้เพื่อรีเฟรชข้อมูลใหม่
  setState(() {});
}

/// ✅ **สร้าง Widget รวมกราฟ**  
  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _buildTitle("Daily Intake (Last 7 Days)"),
          const SizedBox(height: 10),
          SizedBox(height: 200, child: _buildAnimatedBarChart()),
          const SizedBox(height: 30),

          _buildTitle("Medication Type Distribution"),
          const SizedBox(height: 10),
          Expanded(child: _buildInteractivePieChart()),
        ],
      ),
    );
  }

  /// ✅ **Title Widget**
  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFC76355),
      ),
    );
  }

  /// ✅ **Bar Chart (กราฟแท่งแบบ Interactive & Glow)**
  Widget _buildAnimatedBarChart() {
    List<BarChartGroupData> barGroups = List.generate(7, (index) {
      double value = [2, 4, 6, 8, 3, 7, 5][index].toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: touchedIndex == index
                  ? [Colors.deepOrange, Colors.redAccent]
                  : [const Color(0xFFC76355), const Color(0xFFFFA07A)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: touchedIndex == index ? 24 : 16, // 🟠 ขยายขนาดเมื่อกด
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 10,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
        showingTooltipIndicators: touchedIndex == index ? [0] : [],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            setState(() {
              touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
            });
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }

  /// ✅ **Pie Chart (กราฟวงกลมแบบ Interactive)**
  Widget _buildInteractivePieChart() {
    return PieChart(
      PieChartData(
        sections: List.generate(4, (index) {
          List<Color> colors = [
            const Color(0xFFC76355),
            const Color(0xFFFFA07A),
            const Color(0xFFFFD700),
            const Color(0xFF69C8FF),
          ];
          List<String> labels = ["Painkillers", "Vitamins", "Antibiotics", "Others"];
          List<double> values = [40, 30, 20, 10];

          return PieChartSectionData(
            value: values[index],
            color: touchedIndex == index ? colors[index].withOpacity(0.6) : colors[index],
            title: labels[index],
            radius: touchedIndex == index ? 80 : 70,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex ?? -1;
            });
          },
        ),
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> medData) {
    final nameController = TextEditingController(text: medData['M_name']);
    final propertiesController =
        TextEditingController(text: medData['Properties']);
    DateTime? startDate = medData['Start_date'] is Timestamp
        ? (medData['Start_date'] as Timestamp).toDate()
        : DateTime.now();
    DateTime? endDate = medData['End_date'] is Timestamp
        ? (medData['End_date'] as Timestamp).toDate()
        : DateTime.now();
    int frequency =
        int.tryParse(medData['Frequency']?.split(' ')[0] ?? '1') ?? 1;
    List<TimeOfDay> notificationTimes =
        (medData['Notification_times'] as List).map((timeString) {
      final timeParts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFEF4E0),
              title: const Text(
                'Edit Medication',
                style: TextStyle(color: Color(0xFFC76355)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: propertiesController,
                      decoration: const InputDecoration(labelText: 'Properties'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: DateTimeRange(
                            start: startDate!,
                            end: endDate!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC76355),
                      ),
                      child: Text(
                        startDate != null && endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                            : 'Select Date Range',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Frequency:',
                          style: TextStyle(color: Color(0xFFC76355)),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: frequency,
                          items: List.generate(4, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text('${index + 1} times/day'),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              frequency = value!;
                              // Update notification times based on frequency
                              if (frequency == 1) {
                                notificationTimes = [TimeOfDay(hour: 8, minute: 0)];
                              } else if (frequency == 2) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 19, minute: 0)
                                ];
                              } else if (frequency == 3) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 13, minute: 0),
                                  TimeOfDay(hour: 19, minute: 0)
                                ];
                              } else if (frequency == 4) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 12, minute: 0),
                                  TimeOfDay(hour: 16, minute: 0),
                                  TimeOfDay(hour: 20, minute: 0)
                                ];
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Times:',
                          style: TextStyle(color: Color(0xFFC76355)),
                        ),
                        const SizedBox(height: 10),
                        ...notificationTimes.asMap().entries.map((entry) {
                          int index = entry.key;
                          TimeOfDay time = entry.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${index + 1}: ${time.format(context)}',
                                style: const TextStyle(color: Colors.black),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFFC76355)),
                                onPressed: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: time,
                                  );
                                  if (pickedTime != null) {
                                    setDialogState(() {
                                      notificationTimes[index] = pickedTime;
                                    });
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Save updated medication to Firestore
                    try {
                      await FirebaseFirestore.instance
                          .collection('Medications')
                          .doc(docId)
                          .update({
                        'M_name': nameController.text.trim(),
                        'Properties': propertiesController.text.trim(),
                        'Start_date': startDate,
                        'End_date': endDate,
                        'Frequency': '$frequency times/day',
                        'Notification_times': notificationTimes
                            .map((time) =>
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}')
                            .toList(),
                        'Updated_at': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication updated successfully!'),
                        ),
                      );
                    } catch (e) {
                      print('Error updating medication: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update medication!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC76355),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Color(0xFFC76355)),
          ),
          content: const Text(
            'Are you sure you want to delete this medication?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('Medications')
                      .doc(docId)
                      .delete();

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication deleted successfully!'),
                    ),
                  );
                } catch (e) {
                  print('Error deleting medication: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete medication!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}