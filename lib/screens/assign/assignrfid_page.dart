import 'package:flutter/material.dart';
import 'package:tagtime_medicare/screens/assign/assign_medicine_page.dart';

class AssignRFIDPage extends StatefulWidget {
  final String assignType;
  final String? caregiverId;  // เพิ่มพารามิเตอร์
  final String? caregiverName;  // เพิ่มพารามิเตอร์

  AssignRFIDPage({
    required this.assignType, 
    this.caregiverId, 
    this.caregiverName
  });

  @override
  _AssignRFIDPageState createState() => _AssignRFIDPageState();
}

class _AssignRFIDPageState extends State<AssignRFIDPage> {
  String? scannedUID;
  bool isScanning = false;

  void scanRFID() async {
    setState(() {
      isScanning = true;
    });

    // จำลองการสแกน RFID
    await Future.delayed(Duration(seconds: 2));
    String fakeUID = "UID${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      scannedUID = fakeUID;
      isScanning = false;
    });
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'images/LOGOAYD.png',
              height: 50,
            ),
            const SizedBox(height: 20),
            Text(
              'Assign Type: ${widget.assignType}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC76355),
              ),
            ),
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
                      color: Color(0xFFC76355),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Press "Scan RFID" to begin',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFC76355),
                ),
              ),
            const SizedBox(height: 20),
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
            if (scannedUID != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignMedicinePage(
                        uid: scannedUID!,
                        assignType: widget.assignType,
                        caregiverId: widget.caregiverId,
                        caregiverName: widget.caregiverName,
                      ),
                    ),
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