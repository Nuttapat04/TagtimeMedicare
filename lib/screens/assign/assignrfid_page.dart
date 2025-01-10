import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tagtime_medicare/screens/assign/assign_medicine_page.dart';

class AssignRFIDPage extends StatefulWidget {
  final String assignType;

  AssignRFIDPage({required this.assignType});

  @override
  _AssignRFIDPageState createState() => _AssignRFIDPageState();
}

class _AssignRFIDPageState extends State<AssignRFIDPage> {
  String? scannedUID;
  bool isScanning = false;

  Future<void> scanRFID() async {
    setState(() {
      isScanning = true;
    });

    try {
      // เริ่มการสแกน NFC
      NFCTag tag = await FlutterNfcKit.poll();

      // ดึง UID จาก NFC Tag
      setState(() {
        scannedUID = tag.id; // UID ที่ได้จาก NFC Tag
        isScanning = false;
      });

      // ปิดการสแกน
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      // แสดงข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning RFID: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid; // ดึง userId ปัจจุบัน

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Assign RFID',
          style: TextStyle(
            color: Color(0xFFD84315),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFD84315)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'images/LOGOAYD.png',
              height: 50,
            ),
            const SizedBox(height: 20),
            // Assign Type
            Text(
              'Assign Type: ${widget.assignType}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD84315),
              ),
            ),
            const SizedBox(height: 20),
            // สถานะการสแกน
            if (isScanning)
              const CircularProgressIndicator()
            else if (scannedUID != null)
              Column(
                children: [
                  const Text(
                    'RFID Scanned Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'UID: $scannedUID',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD84315),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Press "Scan RFID" to begin',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFD84315),
                ),
              ),
            const SizedBox(height: 20),
            // ปุ่มสแกน
            ElevatedButton(
              onPressed: scanRFID,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                'SCAN RFID',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ปุ่มไปหน้าถัดไป
            if (scannedUID != null)
              ElevatedButton(
                onPressed: userId != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignMedicinePage(
                              uid: scannedUID!,
                              assignBy: widget.assignType,
                              userId: userId, // ส่ง userId ไปยัง AssignMedicinePage
                            ),
                          ),
                        );
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error: User is not logged in')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
