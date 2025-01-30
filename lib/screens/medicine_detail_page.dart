import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

class MedicineDetailPage extends StatefulWidget {
  final Map<String, dynamic> medicineData;
  final String rfidUID;

  const MedicineDetailPage({
    Key? key,
    required this.medicineData,
    required this.rfidUID,
  }) : super(key: key);

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  String currentTime = DateFormat.Hm().format(DateTime.now());
  Map<String, String> statusMap = {}; // เก็บสถานะของแต่ละ Notification Time

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _initializeStatus();
    _autoSaveLateEntries(); // ✅ บันทึก Late อัตโนมัติ
  }

  /// ✅ บันทึก Late อัตโนมัติ ถ้าเลยกำหนดไปแล้ว และยังไม่มีบันทึก
  Future<void> _autoSaveLateEntries() async {
    print("⏳ Checking for late entries...");
    DateTime now = DateTime.now();

    for (String time in widget.medicineData['Notification_times']) {
      bool isMarked = await _checkIfMarkedAlready(time);
      if (isMarked) continue; // ถ้าบันทึกไปแล้ว ข้ามไปเลย!

      DateTime scheduleTime = DateFormat.Hm().parse(time);
      DateTime formattedSchedule = DateTime(
          now.year, now.month, now.day, scheduleTime.hour, scheduleTime.minute);
      Duration difference = now.difference(formattedSchedule);

      // ✅ ถ้าเวลายังไม่ถึง ไม่ต้องทำอะไร
      if (difference.inMinutes < 0) {
        print("🟢 $time is in the future. No need to save.");
        continue;
      }
    }
  }

  /// อัปเดตเวลาปัจจุบันทุกๆ 10 วินาที
  void _updateCurrentTime() {
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        currentTime = DateFormat.Hm().format(DateTime.now());
      });
      _initializeStatus(); // เช็กสถานะใหม่ทุก 10 วินาที
      _updateCurrentTime();
    });
  }

  /// โหลดสถานะของยาแต่ละตัว และอัปเดต statusMap
  /// ✅ ฟังก์ชันตรวจสอบว่ามีการกดบันทึกไปแล้วหรือไม่
  Future<bool> _checkIfMarkedAlready(String time) async {
    String userId = widget.medicineData['user_id'];
    String medicationId = widget.medicineData['RFID_tag'];

    // ✅ ดึงวันที่ปัจจุบันในรูปแบบ YYYY-MM-DD
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: userId)
        .where('Medication_id', isEqualTo: medicationId)
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: today) // ✅ เช็คเฉพาะวันนี้
        .get();

    return snapshot.docs.isNotEmpty; // ถ้ามีเอกสารแสดงว่าเคยกดไปแล้ว
  }

  Future<void> _initializeStatus() async {
    print("🔄 Initializing status...");
    for (String time in widget.medicineData['Notification_times']) {
      print("⏳ Checking status for time: $time");

      bool isMarked = await _checkIfMarkedAlready(time);
      String status = isMarked ? "Marked" : await _checkStatus(time);

      print("📌 Status for $time: $status");

      setState(() {
        statusMap[time] = status;
      });

      // ✅ ถ้ามัน Late แล้ว และยังไม่ถูกบันทึก → เซฟอัตโนมัติ
      if (status == "Late" && !isMarked) {
        print("🔥 Auto-saving $time as Late");
        await _saveToHistory(time, "Late");
      }
    }
  }

  /// ✅ บันทึก `Late` หรือ `On Time` แยกตามวัน และซ่อนปุ่มเมื่อกดแล้ว
  Future<void> _saveToHistory(String time, String status) async {
    String userId = widget.medicineData['user_id'];
    String medicationId = widget.medicineData['RFID_tag'];

    // ✅ ดึงวันที่ปัจจุบัน
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance.collection('Medication_history').add({
      'Intake_time': Timestamp.now(),
      'Scheduled_time': time,
      'Date': today, // ✅ เก็บวันที่เพื่อแยกข้อมูลแต่ละวัน
      'Medication_id': medicationId,
      'Status': status,
      'User_id': userId,
    });

    setState(() {
      statusMap[time] = "Marked"; // ✅ ซ่อนปุ่มเมื่อกดแล้ว
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Saved as $status at $time"),
        backgroundColor: status == "Late" ? Colors.red : Colors.green,
      ),
    );
  }

  Future<String> _checkStatus(String time) async {
    DateTime now = DateTime.now();
    DateTime scheduleTime = DateFormat.Hm().parse(time);
    DateTime formattedSchedule = DateTime(
        now.year, now.month, now.day, scheduleTime.hour, scheduleTime.minute);
    Duration difference = now.difference(formattedSchedule);

    if (difference.inMinutes < 0) {
      // ✅ เวลายังไม่ถึง แค่แสดงเป็น "Upcoming"
      return "Upcoming";
    } else if (difference.inMinutes.abs() <= 120) {
      // ✅ ถ้ายังอยู่ในช่วง 2 ชั่วโมง → แสดง On Time
      return "On Time";
    } else {
      // ✅ ถ้าเลยเวลาไปแล้วเกิน 2 ชั่วโมง → แสดง Late
      return "Late";
    }
  }

  /// ฟังก์ชัน Text-to-Speech อ่านข้อมูลยา
  Future<void> speak() async {
    String textToRead =
        "Name: ${widget.medicineData['M_name'] ?? 'Unknown'}. Instructions: ${widget.medicineData['Properties'] ?? 'No instructions'}. Frequency: ${widget.medicineData['Frequency'] ?? 'Unknown'}.";

    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      setState(() {
        isSpeaking = true;
      });
      await flutterTts.speak(textToRead);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Medicine Details',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: speak,
              icon: Icon(
                isSpeaking ? Icons.stop_circle : Icons.volume_up,
                size: 32,
                color: Colors.white,
              ),
              label: Text(
                isSpeaking ? 'Stop' : 'Read',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC76355),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'Medicine Information',
              child: Column(
                children: [
                  _buildInfoRow('Name', widget.medicineData['M_name'] ?? 'N/A'),
                  _buildInfoRow('Instructions',
                      widget.medicineData['Properties'] ?? 'N/A'),
                  _buildInfoRow(
                      'Frequency', widget.medicineData['Frequency'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// ✅ UI สำหรับการ์ดแสดงข้อมูล "Scheduled Times" พร้อมวันที่
            _buildInfoCard(
              title:
                  'Scheduled Times - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', // ✅ เพิ่มวันที่
              child: Column(
                children: widget.medicineData['Notification_times']
                    .map<Widget>((time) {
                  String status = statusMap[time] ?? "Checking...";
                  return Column(
                    children: [
                      _buildInfoRow('Time', time), // ✅ แสดงเวลาเดิม
                      Center(
                        child: Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: status.contains("Late")
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                      if (status == "On Time")
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _saveToHistory(time, "On Time");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Mark as Taken",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI สำหรับการ์ดแสดงข้อมูล
  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Row UI สำหรับแสดงข้อมูล
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text("$label: ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
