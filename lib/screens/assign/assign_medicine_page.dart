import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignMedicinePage extends StatefulWidget {
  final String uid;
  final String assignBy;
  final String userId; // เพิ่ม userId

  AssignMedicinePage({required this.uid, required this.assignBy, required this.userId});

  @override
  _AssignMedicinePageState createState() => _AssignMedicinePageState();
}

class _AssignMedicinePageState extends State<AssignMedicinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController propertiesController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  int frequency = 1;
  List<TimeOfDay> times = [];
  int currentStep = 1;

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

  Future<void> selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        times[index] = picked;
      });
    }
  }

  Future<void> saveToDatabase() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // ตรวจสอบว่ามี RFID_tag ซ้ำหรือไม่
      final querySnapshot = await firestore
          .collection('Medications')
          .where('RFID_tag', isEqualTo: widget.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await firestore.collection('Medications').doc(docId).delete();
      }

      // เพิ่มข้อมูลใหม่ใน Medications
      await firestore.collection('Medications').add({
        'M_name': nameController.text,
        'Properties': propertiesController.text,
        'Start_date': startDate,
        'End_date': endDate,
        'Frequency': frequency,
        'Notification_times': times
            .map((time) => '${time.hour}:${time.minute}')
            .toList(),
        'RFID_tag': widget.uid,
        'Assigned_by': widget.assignBy,
        'UserId': widget.userId, // บันทึก UserId
        'Created_at': DateTime.now(),
        'Updated_at': DateTime.now(),
      });

      // อัปเดตข้อมูลใน Rfid_tags
      final rfidQuerySnapshot = await firestore
          .collection('Rfid_tags')
          .where('Tag_id', isEqualTo: widget.uid)
          .get();

      if (rfidQuerySnapshot.docs.isNotEmpty) {
        final rfidDocId = rfidQuerySnapshot.docs.first.id;
        await firestore.collection('Rfid_tags').doc(rfidDocId).delete();
      }

      await firestore.collection('Rfid_tags').add({
        'Tag_id': widget.uid,
        'Medication_id': nameController.text,
        'User_id': widget.userId, // บันทึก UserId
        'Status': 'Active',
        'Last_scanned': DateTime.now(),
        'Assigned_by': widget.assignBy,
      });

      // แสดง popup ว่า success
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Medicine assignment completed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog
                  Navigator.of(context).pop(); // ปิดหน้าปัจจุบัน
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // แสดง popup error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save data: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: Text(
          'Assign Medicine - Step $currentStep/3',
          style: const TextStyle(
            color: Color(0xFFD84315),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFD84315)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentStep == 1
            ? buildStep1()
            : currentStep == 2
                ? buildStep2()
                : buildStep3(),
      ),
    );
  }

  Widget buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RFID UID: ${widget.uid}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD84315),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: propertiesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Properties',
            border: OutlineInputBorder(),
          ),
        ),
        const Spacer(),
        Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD84315),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text(
              'Next',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Select Date Range',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD84315),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: selectDateRange,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD84315),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          child: Text(
            startDate != null && endDate != null
                ? '${startDate!.toLocal().toString().split(' ')[0]} - ${endDate!.toLocal().toString().split(' ')[0]}'
                : 'Select Date Range',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentStep = 3;
                  times = List.generate(frequency, (_) => TimeOfDay.now());
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Frequency and Times',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD84315),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Frequency: ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD84315),
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
                  times = List.generate(frequency, (_) => TimeOfDay.now());
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          children: List.generate(
            frequency,
            (index) => ElevatedButton(
              onPressed: () => selectTime(index),
              child: Text(
                times[index] != null
                    ? 'Time ${index + 1}: ${times[index].format(context)}'
                    : 'Select Time ${index + 1}',
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentStep = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: saveToDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
