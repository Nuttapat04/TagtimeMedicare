import 'package:flutter/material.dart';
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
      // Mockup RFID scanning
      await Future.delayed(const Duration(seconds: 2)); // Simulate delay
      String fakeUID = "UID123456789"; // Simulated RFID UID

      setState(() {
        scannedUID = fakeUID; // Assign the simulated UID
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning RFID: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid; // Get current userId

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
            // Scanning status
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
            // Scan Button
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
            // Next Button
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
                              userId: userId, // Pass userId to AssignMedicinePage
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
