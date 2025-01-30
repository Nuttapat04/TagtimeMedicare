import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';

class RFIDPage extends StatefulWidget {
  final VoidCallback onRFIDDetected; // เปลี่ยนเป็น VoidCallback
  final VoidCallback onAssignPressed; // เปลี่ยนเป็น VoidCallback
  final String firstName;

  RFIDPage({
    required this.onRFIDDetected,
    required this.onAssignPressed,
    required this.firstName,
  });

  @override
  _RFIDPageState createState() => _RFIDPageState();
}

class _RFIDPageState extends State<RFIDPage> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // สำหรับเก็บ UID ที่สแกนได้
  String? scannedUID;
  // สำหรับเก็บข้อมูลยา (หากมี)
  Map<String, dynamic>? assignedMedicineData;
  // flag แสดงว่ากำลังสแกนอยู่หรือไม่
  bool isScanning = false;

  @override
  void initState() {
    super.initState();

    // Animation
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();

    // สแกน RFID ทันทีที่เข้าหน้านี้
    scanRFID();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// ฟังก์ชันสแกน RFID อัตโนมัติ
  Future<void> scanRFID() async {
    setState(() => isScanning = true);

    try {
      final result = await MethodChannel('flutter_nfc_reader_writer')
          .invokeMethod<Map>('NfcRead');

      if (result != null && result.containsKey('serialNumber')) {
        String rfidUID = result['serialNumber'];
        setState(() {
          scannedUID = rfidUID;
        });

        // เรียก callback โดยไม่ส่งพารามิเตอร์
        widget.onRFIDDetected();

        // Query ข้อมูลยา
        await fetchAssignedMedicine(rfidUID);
      } else {
        setState(() {
          scannedUID = null;
        });
      }
    } catch (e) {
      print('Error scanning RFID: $e');
      setState(() {
        scannedUID = null;
      });
    } finally {
      setState(() => isScanning = false);
    }
  }

  /// ดึงข้อมูลยาและนำทางไปหน้าแสดงรายละเอียด
  Future<void> fetchAssignedMedicine(String uid) async {
    try {
      // ดึง User ปัจจุบัน
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Query Firestore สำหรับข้อมูลยา
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('RFID_tag', isEqualTo: uid)
          .where('user_id', isEqualTo: userId)
          .get();

      // Query Firestore สำหรับ RFID tag
      final rfidSnapshot = await FirebaseFirestore.instance
          .collection('Rfid_tags')
          .where('Tag_id', isEqualTo: uid)
          .get();

      if (medsSnapshot.docs.isNotEmpty) {
        // ดึงข้อมูลยา
        final medicineData = medsSnapshot.docs.first.data();

        // อัพเดท Last_scanned ถ้าเจอ RFID tag
        if (rfidSnapshot.docs.isNotEmpty) {
          await rfidSnapshot.docs.first.reference.update({
            'Last_scanned': FieldValue.serverTimestamp(),
          });
        }

        // นำทางไปหน้าแสดงรายละเอียดยา
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(
              medicineData: medicineData,
              rfidUID: uid,
            ),
          ),
        );
      } else {
        // แสดง snackbar กรณีไม่พบข้อมูลยา
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No medicine found for this RFID tag'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching medicine: $e');
      // แสดง snackbar กรณีเกิดข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
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
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Place RFID',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ส่วน Welcome message
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Welcome, ${widget.firstName}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC76355),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // ส่วนข้อความกลางและปุ่มสแกนใหม่
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                if (scannedUID == null) ...[
                  const Center(
                    child: Text(
                      'Place your',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFC76355),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Center(
                    child: Text(
                      'medicine',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC76355),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Text(
                      'Your medicine has been',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFC76355),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Center(
                    child: Text(
                      'scanned',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC76355),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 250, // กำหนดความกว้างของปุ่ม
                    height: 60, // กำหนดความสูงของปุ่ม
                    child: ElevatedButton.icon(
                      onPressed: scanRFID,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 28, // เพิ่มขนาดไอคอน
                      ),
                      label: const Text(
                        'Scan Again',
                        style: TextStyle(
                          fontSize: 22, // เพิ่มขนาดตัวอักษร
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC76355),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 3, // เพิ่มเงา
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ส่วนแสดงสถานะการสแกน
          if (isScanning)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFC76355)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scanning...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFC76355),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (scannedUID != null)
              Column(
                children: [
                  Text(
                    'Scanned UID: $scannedUID',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC76355),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              )
            else
              const Text(
                'Cannot read RFID or no UID found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],

          // ปุ่ม Assign
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              onPressed: () {
                widget.onAssignPressed();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC76355),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'ASSIGN MEDICINE',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
