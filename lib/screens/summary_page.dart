import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SummaryPage extends StatefulWidget {
  final String userId;

  SummaryPage({required this.userId});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage>
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
      backgroundColor: const Color(0xFFFEF4E0),
      appBar: AppBar(
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
          labelStyle:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

            final notificationTime = DateTime(
                endDate.year, endDate.month, endDate.day, hour, minute);

            return notificationTime.isAfter(DateTime.now());
          }

          return false;
        }).toList();

        return ListView.builder(
          itemCount: filteredMedications.length,
          itemBuilder: (context, index) {
            final med =
                filteredMedications[index].data() as Map<String, dynamic>;
            final name = med['M_name'] ?? 'No name';
            final time = med['Notification_times'] ?? [];
            final startDate = med['Start_date'] is Timestamp
                ? (med['Start_date'] as Timestamp).toDate()
                : DateTime.now();
            final endDate = med['End_date'] is Timestamp
                ? (med['End_date'] as Timestamp).toDate()
                : DateTime.now();
            final assignedBy = med['Assigned_by'] ?? 'Unknown';

            final formattedStartDate =
                DateFormat('dd/MM/yyyy').format(startDate);
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
                              const SizedBox(height: 50), // เพิ่มระยะห่าง
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
    );
  }

  Widget _buildSummaryPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'รอเชื่อม device จริงก่อน, ยังทำไม่ได้',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC76355)),
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
                      decoration:
                          const InputDecoration(labelText: 'Properties'),
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
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children:
                          List.generate(notificationTimes.length, (index) {
                        return ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: notificationTimes[index],
                            );
                            if (pickedTime != null) {
                              setDialogState(() {
                                notificationTimes[index] = pickedTime;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC76355),
                          ),
                          child: Text(
                            'Time ${index + 1}: ${notificationTimes[index].format(context)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFC76355)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('Medications')
                        .doc(docId)
                        .update({
                      'M_name': nameController.text,
                      'Properties': propertiesController.text,
                      'Start_date': startDate,
                      'End_date': endDate,
                      'Frequency': '$frequency times/day',
                      'Notification_times': notificationTimes.map((time) {
                        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      }).toList(),
                      'Updated_at': Timestamp.now(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Medication updated successfully!')),
                    );
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFC76355)),
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this medication?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Medications')
                    .doc(docId)
                    .delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Medication deleted successfully!')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
