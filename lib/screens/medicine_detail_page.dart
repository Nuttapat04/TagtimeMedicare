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
    _autoSaveLateEntries();
  }

  /// ✅ บันทึก Late อัตโนมัติ ถ้าเลยกำหนดไปแล้ว 2 ชั่วโมง และยังไม่มีบันทึก
  Future<void> _autoSaveLateEntries() async {
    print("⏳ Checking for late entries...");
    DateTime now = DateTime.now();

    for (String time in widget.medicineData['Notification_times']) {
      bool isMarked = await _checkIfMarkedAlready(time);
      if (isMarked) {
        print("⚠️ Already saved for $time - Skipping auto-save.");
        continue; // ✅ ข้ามถ้ามีอยู่แล้ว
      }

      String status = await _checkStatus(time);
      if (status == "Upcoming") {
        print("🟢 $time is still Upcoming. Skipping auto-save.");
        continue;
      }

      if (status == "Late") {
        print("🔥 Auto-saving $time as Late...");
        await _saveToHistory(time, "Late", autoSave: true);
      }
    }
  }

  void _updateCurrentTime() {
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        currentTime = DateFormat.Hm().format(DateTime.now());
      });

      // ✅ เช็กสถานะใหม่ทุก 10 วินาที
      _initializeStatus();
      _updateCurrentTime();
    });
  }

  Future<bool> _checkIfMarkedAlready(String time) async {
    String? userId = widget.medicineData['user_id'];
    String? rfidTag = widget.medicineData['RFID_tag'];
    String? medicationId = widget.medicineData['Medication_id'];

    if (userId == null || rfidTag == null || medicationId == null) {
      print("⚠️ Missing required data. Skipping check.");
      return false;
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: userId)
        .where('RFID_tag', isEqualTo: rfidTag)
        .where('Medication_id', isEqualTo: medicationId)
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: today) // ✅ เช็คเฉพาะของวันปัจจุบัน!
        .get();

    return snapshot.docs.isNotEmpty; // ✅ ถ้ามีข้อมูลแล้ว return true
  }

  Future<void> _initializeStatus() async {
    print("🔄 Initializing status...");

    List<String> notificationTimes =
        (widget.medicineData['Notification_times'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    for (String time in notificationTimes) {
      bool isMarked = await _checkIfMarkedAlready(time);
      String status = isMarked ? "Marked" : await _checkStatus(time);

      print("📌 Status for $time: $status");

      setState(() {
        statusMap[time] = status;
      });
    }
  }

  Future<void> _saveToHistory(String time, String status,
      {bool autoSave = false}) async {
    String userId = widget.medicineData['user_id'];
    String rfidTag = widget.medicineData['RFID_tag'];

    // ✅ ดึง medication_id โดยใช้ RFID Tag
    String? medicationId = await _fetchMedicationId(rfidTag);
    if (medicationId == null) {
      print("❌ Medication ID not found for RFID: $rfidTag");
      return;
    }

    // ✅ ดึงวันที่ปัจจุบัน
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ✅ ตรวจสอบว่ามีข้อมูลอยู่แล้วหรือไม่
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: userId)
        .where('RFID_tag', isEqualTo: rfidTag)
        .where('Medication_id', isEqualTo: medicationId)
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: today)
        .get();

    if (snapshot.docs.isNotEmpty) {
      print("⚠️ Already recorded for $time - Skipping...");
      return;
    }

    // ✅ ถ้ายังไม่มีข้อมูล ให้บันทึก
    await FirebaseFirestore.instance.collection('Medication_history').add({
      'Intake_time': Timestamp.now(),
      'Scheduled_time': time,
      'Date': today,
      'RFID_tag': rfidTag,
      'Medication_id': medicationId,
      'Status': status,
      'User_id': userId,
      'AutoSave': autoSave,
    });

    // ✅ อัปเดต UI ให้ปุ่มหายไป
    setState(() {
      statusMap[time] = "Marked";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Saved as $status at $time"),
        backgroundColor: status == "Late" ? Colors.red : Colors.green,
      ),
    );
  }

  Future<String?> _fetchMedicationId(String rfidTag) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('RFID_tag', isEqualTo: rfidTag)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print("❌ No medication found for RFID: $rfidTag");
        return null;
      }

      var document = snapshot.docs.first;
      String medicationId = document.id; // ใช้ Document ID แทน Medication_id
      return medicationId;
    } catch (e) {
      print("🔥 Error fetching medication_id: $e");
      return null;
    }
  }

  Future<String> _checkStatus(String time) async {
    DateTime now = DateTime.now();
    DateTime scheduleTime = DateFormat.Hm().parse(time);
    DateTime formattedSchedule = DateTime(
        now.year, now.month, now.day, scheduleTime.hour, scheduleTime.minute);
    Duration difference = now.difference(formattedSchedule);

    if (difference.inMinutes < 0) {
      return "Upcoming";
    } else if (difference.inMinutes.abs() <= 120) {
      return "On Time";
    } else {
      return "Late";
    }
  }

  Future<void> speak() async {
    String textToRead = "Name: ${widget.medicineData['M_name'] ?? 'Unknown'}. "
        "Instructions: ${widget.medicineData['Properties'] ?? 'No instructions'}. "
        "Frequency: ${widget.medicineData['Frequency'] ?? 'Unknown'}.";

    print("🔊 Speaking: $textToRead"); // ✅ Debugging Log

    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      setState(() {
        isSpeaking = true;
      });

      flutterTts.setLanguage("en-US"); // ✅ ตั้งภาษา
      flutterTts.setSpeechRate(0.5); // ✅ ความเร็วเสียง
      flutterTts.setVolume(1.0); // ✅ ระดับเสียง
      flutterTts.setPitch(1.0); // ✅ ระดับโทนเสียง

      int result = await flutterTts.speak(textToRead);
      if (result == 1) {
        print("✅ TTS Started Successfully");
      } else {
        print("❌ TTS Failed to Start");
      }
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
        centerTitle: true,
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
            _buildInfoCard(
              title:
                  'Scheduled Times - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              child: Column(
                children: widget.medicineData['Notification_times']
                    .map<Widget>((time) {
                  String status = statusMap[time] ?? "Checking...";

                  return Column(
                    children: [
                      _buildInfoRow('Time', time),
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
                      if (status == "On Time" && statusMap[time] != "Marked")
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _saveToHistory(time, "On Time");
                              setState(() {
                                statusMap[time] = "Marked"; // ✅ อัปเดต UI ทันที
                              });
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
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
