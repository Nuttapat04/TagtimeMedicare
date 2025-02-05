import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignMedicinePage extends StatefulWidget {
  final String uid;
  final String assignType;
  final String? caregiverId;
  final String? caregiverName;
  final String
      assignSource; // เพิ่มตัวแปรนี้เพื่อบอกว่ามาจาก SIMULATED หรือ RFID

  AssignMedicinePage({
    required this.uid,
    required this.assignType,
    this.caregiverId,
    this.caregiverName,
    required this.assignSource,
  });

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
  }

  Future<void> selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  bool validateForm() {
    // Check if medicine name is empty
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medicine name')),
      );
      return false;
    }

    // Check if properties are empty
    if (propertiesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medicine properties')),
      );
      return false;
    }

    // Check if date range is selected
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return false;
    }

    return true;
  }

  Future<void> removeOldData(String rfidTag, String userId) async {
    // 1) ลบจาก Rfid_tags
    final rfidCollection = FirebaseFirestore.instance.collection('Rfid_tags');
    final oldRfidDocs = await rfidCollection
        .where('RFID_tag', isEqualTo: rfidTag)
        .where('user_id', isEqualTo: userId)
        .get();

    for (var docSnapshot in oldRfidDocs.docs) {
      await docSnapshot.reference.delete();
    }

    // 2) ลบจาก Medications
    final medCollection = FirebaseFirestore.instance.collection('Medications');
    final oldMedDocs = await medCollection
        .where('RFID_tag', isEqualTo: rfidTag)
        .where('user_id', isEqualTo: userId)
        .get();

    for (var docSnapshot in oldMedDocs.docs) {
      await docSnapshot.reference.delete();
    }
  }

  Future<void> saveToDatabase() async {
    if (!validateForm()) return;

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // ลบข้อมูลเก่า
      await removeOldData(widget.uid, userId);

      // แปลง TimeOfDay เป็น String format "HH:mm"
      List<String> formattedTimes = notificationTimes.map((time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }).toList();

      // บันทึกข้อมูลใน Medications collection
      final medicationDoc =
          FirebaseFirestore.instance.collection('Medications').doc();
      await medicationDoc.set({
        'user_id': userId,
        'RFID_tag': widget.uid,
        'Assign_source': widget.assignSource,
        'M_name': nameController.text.trim(),
        'Properties': propertiesController.text.trim(),
        'Start_date': Timestamp.fromDate(startDate!),
        'End_date': Timestamp.fromDate(endDate!),
        'Frequency': '$frequency times/day',
        'Notification_times': formattedTimes,
        'Assigned_by': widget.assignType,
        'Caregiver_id': widget.caregiverId,
        'Caregiver_name': widget.caregiverName,
        'Created_at': FieldValue.serverTimestamp(),
        'Updated_at': FieldValue.serverTimestamp(),
      });

      // บันทึกข้อมูลใน Rfid_tags collection
      final rfidDoc = FirebaseFirestore.instance.collection('Rfid_tags').doc();
      await rfidDoc.set({
        'Tag_id': widget.uid,
        'user_id': userId,
        'Assign_source': widget.assignSource,
        'Assign_by': widget.assignType,
        'Status': 'Active',
        'Medication_id': medicationDoc.id, // เก็บ reference ไปยังเอกสารยา
        'Last_scanned': null,
        'Created_at': FieldValue.serverTimestamp(),
        'Updated_at': FieldValue.serverTimestamp(),
      });

      // เพิ่ม caregiver information ถ้ามี
      if (widget.caregiverId != null && widget.caregiverName != null) {
        await medicationDoc.update({
          'caregiver_id': widget.caregiverId,
          'caregiver_name': widget.caregiverName,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // กลับไปสองหน้า
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text(
          'Assign Medicine',
          style: TextStyle(
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
            // แสดง UID และ Assign Source
            Text(
              'UID: ${widget.uid}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),
            Text(
              'ASSIGN SOURCE: ${widget.assignSource}', // แสดงว่าเป็น RFID หรือ SIMULATED
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
                labelText: 'ชื่อ ยา *',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Color(0xFFC76355)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: propertiesController,
              decoration: const InputDecoration(
                labelText: 'คุณสมบัติ *',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Color(0xFFC76355)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: selectDateRange,
              child: Text(
                'โปรดเลือกระยะเวลา *: ${startDate != null && endDate != null ? '${startDate!.toLocal().toString().split(' ')[0]} to ${endDate!.toLocal().toString().split(' ')[0]}' : 'เลือก วัน'}',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC76355),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'จำนวณครั้งต่อวัน: ',
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
                      child: Text('${index + 1} ครั้ง/วัน'),
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
                    title: Text('ครั้งที่ ${index + 1}'),
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
                        backgroundColor: Color(0xFFC76355),
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
                    backgroundColor: Color(0xFFC76355),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text(
                    'บันทึก การจ่ายยา',
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
