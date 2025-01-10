import 'package:flutter/material.dart';
import 'package:tagtime_medicare/screens/assign_page.dart';
import 'package:tagtime_medicare/screens/assign/assign_medicine_page.dart';


class RFIDPage extends StatelessWidget {
  final Function onRFIDDetected;
  final Function onAssignPressed;
  final String firstName;

  RFIDPage({
    required this.onRFIDDetected,
    required this.onAssignPressed,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Place RFID',
          style: TextStyle(
            color: Color(0xFFD84315),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFD84315)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.center, // ทำให้เนื้อหาอยู่กึ่งกลางในแนวนอน
        children: [
          // ส่วน Logo และข้อความด้านบน
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.center, // เน้นให้อยู่ตรงกลาง
              children: [
                const SizedBox(height: 10),
                Center(
                  // ใช้ Center หุ้มข้อความ Welcome
                  child: Text(
                    'Welcome, $firstName',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD84315),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // ข้อความกลาง
          Column(
            children: const [
              Center(
                // ใช้ Center หุ้มข้อความ
                child: Text(
                  'Place your',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD84315),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                // ใช้ Center หุ้มข้อความ
                child: Text(
                  'medicine',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD84315),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          // ปุ่ม Assign
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0), // ปรับตำแหน่งขึ้น
            child: ElevatedButton(
              onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssignPage()),
                  );
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315), // สีปุ่ม Assign
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 15),
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







