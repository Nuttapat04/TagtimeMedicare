import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medicine_detail_page.dart';

class SimulatedMedicineListPage extends StatefulWidget {
  @override
  _SimulatedMedicineListPageState createState() =>
      _SimulatedMedicineListPageState();
}

class _SimulatedMedicineListPageState extends State<SimulatedMedicineListPage> {
  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text(
          'Simulated Medicines',
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Medications')
            .where('user_id', isEqualTo: userId)
            .where('Assign_source', isEqualTo: 'SIMULATED') // ✅ ดึงแค่ SIMULATED
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final meds = snapshot.data!.docs;

          if (meds.isEmpty) {
            return const Center(
              child: Text(
                'No simulated medications found',
                style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
              ),
            );
          }

          return ListView.builder(
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final medData = meds[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    medData['M_name'] ?? 'Unknown Medicine',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC76355),
                    ),
                  ),
                  subtitle: Text(
                    'Frequency: ${medData['Frequency'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFFC76355)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineDetailPage(
                          medicineData: medData,
                          rfidUID: "SIMULATED", // ไม่มี RFID จริง
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
