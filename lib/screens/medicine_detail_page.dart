import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Set<String> markedTimes = {}; // ✅ เก็บเวลากดบันทึกแล้ว

  @override
  void initState() {
    super.initState();
    _initializeStatus();

  }

  Future<void> _initializeStatus() async {
    print("🔄 Initializing status...");

    final prefs = await SharedPreferences.getInstance();
    List<String> savedMarkedTimes =
        prefs.getStringList('markedTimes_${widget.rfidUID}') ?? [];
    markedTimes = savedMarkedTimes.toSet();

    List<String> notificationTimes =
        (widget.medicineData['Notification_times'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    // ✅ ตรวจสอบว่า Medication_id เป็น null และดึงค่าใหม่จาก Firestore
    if (widget.medicineData['Medication_id'] == null) {
      String? medicationId =
          await _fetchMedicationId(widget.medicineData['RFID_tag']);

      if (medicationId != null) {
        widget.medicineData['Medication_id'] = medicationId;
        print("🔄 Updated widget.medicineData['Medication_id']: $medicationId");
      } else {
        print("⚠️ Medication_id ยังเป็น null, ข้ามการตั้งค่า...");
        return;
      }
    }

    if (widget.medicineData['user_id'] == null ||
        widget.medicineData['RFID_tag'] == null ||
        widget.medicineData['Medication_id'] == null) {
      print("⚠️ ข้อมูลไม่ครบ (ยังหา Medication_id ไม่เจอ)");
      return;
    }

    await Future.wait(notificationTimes.map((time) async {
      bool isMarked =
          markedTimes.contains(time) || await _checkIfMarkedAlready(time);

      if (isMarked) {
        statusMap[time] = "Marked";
      } else {
        statusMap[time] = await _checkStatus(time);
      }
    }));

    setState(() {});
  }

  Future<void> saveMarkedTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'markedTimes_${widget.rfidUID}', markedTimes.toList());
  }

  Future<void> _autoSaveLateEntries() async {
    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    // เช็คว่ามีการบันทึกแล้วหรือไม่
    QuerySnapshot existingRecords = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: widget.medicineData['user_id'])
        .where('RFID_tag', isEqualTo: widget.medicineData['RFID_tag'])
        .where('Date', isEqualTo: today)
        .get();

    Set<String> recordedTimes = existingRecords.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .map((data) => data['Scheduled_time'] as String)
        .toSet();

    for (String time in widget.medicineData['Notification_times']) {
      if (recordedTimes.contains(time)) continue;

      String status = await _checkStatus(time);
      if (status == "Late") {
        await _saveToHistory(time, "Late", autoSave: true);
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Marked":
        return Colors.grey;
      case "Skipped":
        return Colors.orange; // สีส้มสำหรับ Skip
      case "Late":
        return Colors.red;
      case "On Time":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<bool> _checkIfMarkedAlready(String time) async {
    String? userId = widget.medicineData['user_id'];
    String? rfidTag = widget.medicineData['RFID_tag'];
    String? medicationId = widget.medicineData['Medication_id'];

    if (userId == null || rfidTag == null || medicationId == null) {
      print(
          "⚠️ Missing required data in _checkIfMarkedAlready(). Skipping check.");
      return false;
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: userId)
        .where('RFID_tag', isEqualTo: rfidTag)
        .where('Medication_id', isEqualTo: medicationId)
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: today)
        .where('mark', isEqualTo: true)
        .where('AutoSave', isEqualTo: false)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _saveToHistory(String time, String status,
      {bool autoSave = false}) async {
    String userId = widget.medicineData['user_id'];
    String rfidTag = widget.medicineData['RFID_tag'];

    String? medicationId = await _fetchMedicationId(rfidTag);
    if (medicationId == null) {
      print("❌ Medication ID not found for RFID: $rfidTag");
      return;
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
      setState(() {
        statusMap[time] = "Marked";
      });
      return;
    }

    // ✅ บันทึกลง Firestore
    await FirebaseFirestore.instance.collection('Medication_history').add({
      'Intake_time': Timestamp.now(),
      'Scheduled_time': time,
      'Date': today,
      'RFID_tag': rfidTag,
      'Medication_id': medicationId,
      'Status': status,
      'User_id': userId,
      'AutoSave': autoSave, // ✅ บันทึกว่าเป็น Auto Save หรือไม่
      'mark': true,
    });

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

  void listenToMedicationChanges(String userId) {
    print('❌ Firestore snapshot listener removed');
  }

  Future<String?> _fetchMedicationId(String rfidTag) async {
    if (rfidTag.isEmpty) {
      print("⚠️ RFID Tag is empty!");
      return null;
    }

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

      String medicationId = snapshot.docs.first.id; // ✅ ใช้ document ID แทน
      print("✅ Medication_id found: $medicationId");
      return medicationId;
    } catch (e) {
      print("🔥 Error fetching medication_id: $e");
      return null;
    }
  }

  Future<String> _checkStatus(String time) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: widget.medicineData['user_id'])
        .where('RFID_tag', isEqualTo: widget.medicineData['RFID_tag'])
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: today)
        .where('Status', isEqualTo: 'Skip')
        .get();

    if (snapshot.docs.isNotEmpty) {
      return "Skipped";
    }

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
      return "Late"; // ✅ ใช้ "Late" ได้ แต่ยังไม่บันทึกลง Firestore
    }
  }

  Future<void> speak() async {
    String name = widget.medicineData['M_name'] ?? 'Unknown';
    String instructions =
        widget.medicineData['Properties'] ?? 'No instructions';
    String frequency = widget.medicineData['Frequency'] ?? 'Unknown';

    String textToRead =
        "ชื่อยา: $name. รายละเอียดยา: $instructions. ความถี่: $frequency.";

    // เช็คว่ามีข้อความเป็นภาษาไทยไหม
    bool containsThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(textToRead);

    String selectedLanguage = containsThai ? "th-TH" : "en-US";

    print("🔊 Speaking ($selectedLanguage): $textToRead");

    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      setState(() {
        isSpeaking = true;
      });

      flutterTts.setLanguage(selectedLanguage);
      flutterTts.setSpeechRate(0.5);
      flutterTts.setVolume(1.0);
      flutterTts.setPitch(1.0);

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
          'ข้อมูลยา',
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
              onPressed: speak, // ✅ กดแล้วอ่านออกเสียง
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
            /// 🔥 **เอา Information กลับมา**
            _buildInfoCard(
              title: 'ข้อมูลยา',
              child: Column(
                children: [
                  _buildInfoRow(
                      'ชื่อยา', widget.medicineData['M_name'] ?? 'N/A'),
                  _buildInfoRow(
                      'รายละเอียด', widget.medicineData['Properties'] ?? 'N/A'),
                  _buildInfoRow(
                      'ความถี่', widget.medicineData['Frequency'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// ✅ **Scheduled Times**
            _buildInfoCard(
              title:
                  'วันที่ - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              child: Column(
                children: widget.medicineData['Notification_times']
                    .map<Widget>((time) {
                  String status = statusMap[time] ?? "Checking...";
                  bool isMarked =
                      markedTimes.contains(time); // ✅ ใช้ Set ที่เราเก็บไว้

                  return Column(
                    children: [
                      _buildInfoRow('เวลา', time),
                      Center(
                        child: Text(
                          'สถานะ: ${isMarked ? "Marked" : status}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: getStatusColor(isMarked ? "Marked" : status),
                          ),
                        ),
                      ),
                      if (!isMarked &&
                          (status == "On Time" || status == "Late"))
                        Center(
                            child: ElevatedButton(
                          onPressed: () async {
                            String status = await _checkStatus(time);

                            // ✅ ถ้าเป็น "Late" และยังไม่ถูก mark ให้บันทึกเมื่อกดปุ่ม
                            if (status == "Late" &&
                                !markedTimes.contains(time)) {
                              await _saveToHistory(time, "Late");
                            } else {
                              await _saveToHistory(time, status);
                            }
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
                            "กดเมื่อใช้ยาแล้ว",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
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
