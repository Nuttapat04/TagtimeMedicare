import 'package:flutter/material.dart';
import 'nfc_reader_writer.dart';

class NFCPage extends StatefulWidget {
  @override
  _NFCPageState createState() => _NFCPageState();
}

class _NFCPageState extends State<NFCPage> {
  String nfcStatus = "Ready";
  String? nfcContent;
  final TextEditingController _writeController = TextEditingController();

  // Read data from NFC
  void startRead() async {
    setState(() {
      nfcStatus = "Reading...";
    });
    try {
      final NfcData result = await FlutterNfcReaderWriter.read();
      setState(() {
        nfcStatus = "Read Successful";
        nfcContent = result.content;
      });
    } catch (e) {
      setState(() {
        nfcStatus = "Read Failed: $e";
      });
    }
  }

  // Write data to NFC
  void startWrite() async {
    final dataToWrite = _writeController.text.trim();
    if (dataToWrite.isEmpty) {
      setState(() {
        nfcStatus = "Please enter data to write";
        return;
      });
    }

    setState(() {
      nfcStatus = "Writing...";
    });

    try {
      final NfcData result = await FlutterNfcReaderWriter.write(dataToWrite);
      setState(() {
        nfcStatus = "Write Successful: ${result.content}";
      });
    } catch (e) {
      setState(() {
        nfcStatus = "Write Failed: $e";
      });
    }
  }

  // Check NFC Availability
  void checkAvailability() async {
    final isAvailable = await FlutterNfcReaderWriter.checkAvailability();
    if (!isAvailable) {
      setState(() {
        nfcStatus = "NFC is not available on this device.";
      });
    } else {
      setState(() {
        nfcStatus = "NFC is available. Ready to use.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFC Reader & Writer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Status: $nfcStatus",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (nfcContent != null) ...[
              Text(
                "NFC Content: $nfcContent",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
            ],
            TextField(
              controller: _writeController,
              decoration: InputDecoration(
                labelText: "Enter text to write",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: startWrite,
              child: Text("Write to NFC"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startRead,
              child: Text("Read NFC Tag"),
            ),
          ],
        ),
      ),
    );
  }
}
