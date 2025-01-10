import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int currentStep = 1;
  List<TimeOfDay> notificationTimes = [TimeOfDay.now()];

  void updateNotificationTimes() {
    setState(() {
      // Adjust the number of TimeOfDay objects based on frequency
      notificationTimes = List.generate(frequency, (index) => TimeOfDay.now());
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

  Future<void> selectTime(int index) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: notificationTimes[index],
    );
    if (pickedTime != null) {
      setState(() {
        notificationTimes[index] = pickedTime;
      });
    }
  }

  Future<void> saveToDatabase() async {
    try {
      final medicationDoc = FirebaseFirestore.instance.collection('Medications').doc();

      // Format times to strings
      List<String> formattedTimes = notificationTimes.map((time) {
        return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }).toList();

      await medicationDoc.set({
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

      Navigator.pop(context); // Go back after saving
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 1),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentStep = 2;
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
                  updateNotificationTimes();
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Select Frequency & Times',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD84315),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  updateNotificationTimes();
                });
              },
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notificationTimes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Time ${index + 1}'),
                trailing: ElevatedButton(
                  onPressed: () => selectTime(index),
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
