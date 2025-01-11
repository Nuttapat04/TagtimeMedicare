import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignMedicinePage extends StatefulWidget {
  final String uid;

  AssignMedicinePage({required this.uid});

  @override
  _AssignMedicinePageState createState() => _AssignMedicinePageState();
}

class _AssignMedicinePageState extends State<AssignMedicinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController propertiesController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  int frequency = 1;
  List<TimeOfDay> notificationTimes = [TimeOfDay(hour: 8, minute: 0)];

  void updateNotificationTimes() {
    setState(() {
      if (frequency == 1) {
        notificationTimes = [TimeOfDay(hour: 8, minute: 0)];
      } else if (frequency == 2) {
        notificationTimes = [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 19, minute: 0)];
      } else if (frequency == 3) {
        notificationTimes = [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 19, minute: 0)];
      } else if (frequency == 4) {
        notificationTimes = [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 12, minute: 0),
          TimeOfDay(hour: 16, minute: 0),
          TimeOfDay(hour: 20, minute: 0)
        ];
      }
    });
  }

  Future<void> selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> saveToDatabase() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final medicationDoc = FirebaseFirestore.instance.collection('Medications').doc();

      List<String> formattedTimes = notificationTimes.map((time) {
        return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }).toList();

      await medicationDoc.set({
        'user_id': userId,
        'RFID_tag': widget.uid,
        'M_name': nameController.text,
        'Properties': propertiesController.text,
        'Start_date': startDate,
        'End_date': endDate,
        'Frequency': '$frequency times/day',
        'Notification_times': formattedTimes,
        'Created_at': Timestamp.now(),
        'Updated_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medication assigned successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign medication!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        title: Text(
          'Assign Medicine',
          style: const TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UID: ${widget.uid}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Color(0xFFC76355)),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: propertiesController,
              decoration: const InputDecoration(
                labelText: 'Properties',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Color(0xFFC76355)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: selectDateRange,
              child: Text(
                'Select Date Range: ${startDate != null && endDate != null ? '${startDate!.toLocal().toString().split(' ')[0]} to ${endDate!.toLocal().toString().split(' ')[0]}' : 'Select Dates'}',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                const Text(
                  'Frequency: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC76355),
                  ),
                ),
                DropdownButton<int>(
                  value: frequency,
                  items: List.generate(4, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1} times/day'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      frequency = value!;
                      updateNotificationTimes();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: notificationTimes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Time ${index + 1}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: notificationTimes[index],
                        );
                        if (pickedTime != null) {
                          setState(() {
                            notificationTimes[index] = pickedTime;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD84315),
                      ),
                      child: Text(
                        '${notificationTimes[index].hour.toString().padLeft(2, '0')}:${notificationTimes[index].minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 30),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: saveToDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD84315),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text(
                    'Save Medication',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}