import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tagtime_medicare/screens/assign/assign_medicine_page.dart';

class AssignRFIDPage extends StatefulWidget {
  final String assignType;
  final String? caregiverId;
  final String? caregiverName;

  AssignRFIDPage({
    required this.assignType,
    this.caregiverId,
    this.caregiverName,
  });

  @override
  _AssignRFIDPageState createState() => _AssignRFIDPageState();
}

class _AssignRFIDPageState extends State<AssignRFIDPage> {
  static const platform = MethodChannel('flutter_nfc_reader_writer');

  String? scannedUID;
  bool isScanning = false;
  String? assignSource; // เก็บข้อมูลว่ามาจาก RFID จริง หรือ Simulated

  // สร้าง Simulated UID
  void generateFakeUID() async {
    setState(() {
      isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    String fakeSerialNumber = "SN${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      scannedUID = fakeSerialNumber;
      isScanning = false;
      assignSource = 'SIMULATED'; // บ่งบอกว่า UID นี้เป็นแบบจำลอง
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated UID: $fakeSerialNumber')),
    );
  }

  // สแกน Real UID ผ่าน MethodChannel
  void scanRealRFID() async {
    setState(() => isScanning = true);

    try {
      final result = await platform.invokeMethod('NfcRead');
      final String serialNumber = result['serialNumber'];

      setState(() {
        scannedUID = serialNumber;
        isScanning = false;
        assignSource = 'RFID'; // บ่งบอกว่า UID นี้มาจาก RFID จริง
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned UID: $serialNumber')),
      );
    } catch (e) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading NFC: $e')),
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
        title: const Text(
          'Assign RFID',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้
            Image.asset(
              'images/LOGOAYD.png',
              height: 50,
            ),
            const SizedBox(height: 20),

            // แสดงข้อมูล Assign Type
            Text(
              'Assign Type: ${widget.assignType}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),

            // ถ้ามี Caregiver Name จะแสดง
            if (widget.caregiverName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Caregiver: ${widget.caregiverName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC76355),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // กรณีกำลังสแกน
            if (isScanning)
              const CircularProgressIndicator()
            // ถ้า scannedUID != null แสดงข้อความ "UID Scanned..."
            else if (scannedUID != null)
              Column(
                children: [
                  const Text(
                    'UID Scanned Successfully!',
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
                      color: Color(0xFFC76355),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ปุ่ม NEXT
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignMedicinePage(
                            uid: scannedUID!,
                            assignType: widget.assignType,
                            caregiverId: widget.caregiverId,
                            caregiverName: widget.caregiverName,
                            assignSource: assignSource ?? 'UNKNOWN',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    label: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Select an option to begin',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFC76355),
                ),
              ),

            const SizedBox(height: 20),

            // ปุ่ม USE SIMULATED UID
            ElevatedButton.icon(
              onPressed: generateFakeUID,
              icon: const Icon(Icons.sim_card, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              label: const Text(
                'USE SIMULATED UID',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ปุ่ม SCAN RFID
            ElevatedButton.icon(
              onPressed: scanRealRFID,
              icon: const Icon(Icons.nfc, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              label: const Text(
                'SCAN RFID',
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
