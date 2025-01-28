import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDetailPage extends StatefulWidget {
  final String payload;

  const NotificationDetailPage({Key? key, required this.payload})
      : super(key: key);

  @override
  _NotificationDetailPageState createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  String medicineName = "";
  String medicineProperties = "";
  bool isLoading = true;
  bool isTaken = false;

  @override
  void initState() {
    super.initState();
    print("📩 Opened NotificationDetailPage with payload: ${widget.payload}");
    fetchMedicineDetails();
  }

  Future<void> fetchMedicineDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // ❌ User ไม่ได้ล็อกอิน
    if (userId == null) {
      print("❌ Error: User is not logged in");
      setState(() {
        medicineName = "Error";
        medicineProperties = "กรุณาเข้าสู่ระบบใหม่อีกครั้ง";
        isLoading = false;
      });
      return;
    }

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('user_id', isEqualTo: userId)
          .where('M_name',
              isEqualTo: widget.payload) // ✅ เช็คว่าชื่อตรงกับ payload
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        setState(() {
          medicineName = doc['M_name'];
          medicineProperties = doc['Properties'];
          isLoading = false;
        });
        print("✅ Fetched medicine details: $medicineName");
      } else {
        print("⚠️ No medication found for: ${widget.payload}");
        setState(() {
          medicineName = "ไม่พบข้อมูล";
          medicineProperties = "ไม่มีรายละเอียดเกี่ยวกับยานี้";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching medicine details: $e");
      setState(() {
        medicineName = "Error";
        medicineProperties = "ไม่สามารถดึงข้อมูลได้";
        isLoading = false;
      });
    }
  }

  Future<void> markAsTaken() async {
    setState(() {
      isTaken = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ บันทึกว่ากินยาแล้ว!")),
    );

    // เพิ่ม Log ใน Firestore ว่ากินยาแล้ว
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance.collection("Medication_history").add({
          "user_id": userId,
          "M_name": medicineName,
          "Taken_at": Timestamp.now(),
        });
        print("✅ Medication marked as taken for $medicineName");
      } catch (e) {
        print("❌ Error saving medication history: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📌 รายละเอียดการแจ้งเตือน"),
        backgroundColor: const Color(0xFFFFF4E0),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "💊 ชื่อยา: $medicineName",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "📄 สรรพคุณ: $medicineProperties",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  if (!isTaken)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: markAsTaken,
                        child: const Text("✅ กินยารึยัง?"),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        "✅ กินยาแล้ว!",
                        style: TextStyle(color: Colors.green, fontSize: 18),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
