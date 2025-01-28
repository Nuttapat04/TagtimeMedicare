import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  @override
  void initState() {
    super.initState();
    print('🏥 MedicineDetailPage initialized');
    print('🏥 Medicine Data: ${widget.medicineData}');
    print('🏥 RFID UID: ${widget.rfidUID}');
    initTTS();
  }

  Future<void> initTTS() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  String _getTextToRead() {
    final name = widget.medicineData['M_name'] ?? 'ไม่ระบุ';
    final properties = widget.medicineData['Properties'] ?? 'ไม่ระบุ';
    final frequency = widget.medicineData['Frequency'] ?? 'ไม่ระบุ';

    return 'ชื่อยา $name. วิธีการใช้ยา $properties. ความถี่ในการทานยา $frequency';
  }

  Future<void> speak() async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      setState(() {
        isSpeaking = true;
      });
      await flutterTts.speak(_getTextToRead());
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Details',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFFC76355), size: 32),
          onPressed: () => Navigator.pop(context),
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
                isSpeaking ? 'หยุดอ่าน' : 'อ่านข้อมูลยา',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'RFID Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Tag ID', widget.rfidUID),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                title: 'Medicine Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Name', widget.medicineData['M_name'] ?? 'N/A'),
                    _buildInfoRow('Properties',
                        widget.medicineData['Properties'] ?? 'N/A'),
                    _buildInfoRow(
                        'Frequency', widget.medicineData['Frequency'] ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                title: 'Schedule',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRow(
                        'Start Date', widget.medicineData['Start_date']),
                    _buildDateRow('End Date', widget.medicineData['End_date']),
                    if (widget.medicineData['Notification_times'] != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notification Times:',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC76355),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children:
                            (widget.medicineData['Notification_times'] as List)
                                .map((time) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: const Color(0xFFC76355),
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        time.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFFC76355),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ))
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC76355),
            ),
          ),
          const SizedBox(height: 16),
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
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC76355),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, dynamic date) {
    String formattedDate = 'N/A';
    if (date != null && date is Timestamp) {
      DateTime dateTime = date.toDate();
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return _buildInfoRow(label, formattedDate);
  }
}
