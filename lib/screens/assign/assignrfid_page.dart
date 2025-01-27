import 'package:flutter/material.dart';
import 'package:tagtime_medicare/screens/assign/assign_medicine_page.dart';
import 'package:nfc_manager/nfc_manager.dart';

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
  String? scannedUID;
  bool isScanning = false;

  void generateFakeUID() async {
    setState(() {
      isScanning = true;
    });

    // จำลองการสร้าง UID ปลอม
    await Future.delayed(Duration(seconds: 2));
    String fakeUID = "UID${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      scannedUID = fakeUID;
      isScanning = false;
    });
  }

void scanRealRFID() async {
  setState(() => isScanning = true);

  try {
    bool isAvailable = await NfcManager.instance.isAvailable();
    print("NFC Available: $isAvailable");

    if (!isAvailable) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          print("Tag discovered: ${tag.data}");

          // ตรวจสอบข้อมูล tag
          final mifare = tag.data['mifare'];
          if (mifare == null) {
            throw 'Tag is not MIFARE format';
          }

          final identifier = mifare['identifier'];
          if (identifier == null) {
            throw 'No identifier found';
          }

          // แปลง UID เป็น String
          final uid = List<int>.from(identifier)
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join('')
              .toUpperCase();

          print("Processed UID: $uid");

          setState(() {
            scannedUID = uid;
            isScanning = false;
          });

          await NfcManager.instance.stopSession();

          // ส่ง UID ไปยัง AssignMedicinePage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignMedicinePage(
                uid: uid,
                assignType: widget.assignType,
                caregiverId: widget.caregiverId,
                caregiverName: widget.caregiverName,
              ),
            ),
          );
        } catch (e) {
          print("Error processing tag: $e");
          await NfcManager.instance.stopSession();
          setState(() => isScanning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reading tag: $e')),
          );
        }
      },
      onError: (NfcError error) async {
        print("NFC Error: ${error.message}");
        await NfcManager.instance.stopSession();
        setState(() => isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC Error: ${error.message}')),
        );
      },
    );
  } catch (e) {
    print("Error starting NFC: $e");
    setState(() => isScanning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error starting NFC: $e')),
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
            const SizedBox(height: 20),
            if (scannedUID != null)
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
        ),
      ),
    );
  }
}
