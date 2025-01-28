import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';

class MedicationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ✅ ฟังก์ชันสำหรับตั้งค่าการแจ้งเตือนจาก Firebase
  Future<void> fetchAndScheduleNotifications(String userId) async {
    print('📡 Fetching medications for userId: $userId...');
    final QuerySnapshot medsSnapshot = await firestore
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .get();

    for (var doc in medsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final medicationName = data['M_name'] ?? 'Unknown';
      final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
      final startDate = (data['Start_date'] as Timestamp).toDate();
      final endDate = (data['End_date'] as Timestamp).toDate();
      final now = DateTime.now();

      // เช็คช่วงเวลาเริ่มต้น-สิ้นสุด
      print('📅 Start Date: $startDate');
      print('📅 End Date: $endDate');
      print('⏳ Now: $now');

      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        print('⏭️ Skipping $medicationName: Out of date range.');
        continue;
      }

      // วนลูปตาม Notification Times
      for (String time in notificationTimes) {
        final hour = int.parse(time.split(':')[0]);
        final minute = int.parse(time.split(':')[1]);

        final DateTime scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        final adjustedDate = scheduledDate.isBefore(now)
            ? scheduledDate.add(const Duration(days: 1))
            : scheduledDate;

        print('📅 Scheduling notification for: 💊 Medication Reminder at $adjustedDate (Local TZ)');

        try {
          await NotificationService().scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: '💊 Medication Reminder',
            body: 'Time to take $medicationName.',
            scheduledDate: adjustedDate,
            payload: medicationName,
          );
          print('✅ Notification scheduled for $medicationName at $adjustedDate');
        } catch (e) {
          print('❌ Error scheduling notification for $medicationName: $e');
        }
      }
    }
    print('✅ All notifications have been scheduled.');
  }

  // ✅ ฟังก์ชันสำหรับฟังการเปลี่ยนแปลงของ Firebase และอัปเดต Notification
  void listenToMedicationChanges(String userId) {
  print("👀 Listening for medication changes for userId: $userId...");
  
  firestore
      .collection('Medications')
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .listen((QuerySnapshot snapshot) async {
    print("🔄 Medication data changed in Firestore! Updating notifications...");

    // Debug Log: แสดงข้อมูลที่อัปเดต
    for (var doc in snapshot.docs) {
      print("📌 Updated Medication: ${doc.id}");
      print("   🏷️ Name: ${doc['M_name']}");
      print("   ⏰ Notification Times: ${doc['Notification_times']}");
      print("   📆 Start Date: ${(doc['Start_date'] as Timestamp).toDate()}");
      print("   📆 End Date: ${(doc['End_date'] as Timestamp).toDate()}");
    }

    await NotificationService().cancelAllNotifications(); // ลบแจ้งเตือนเก่าทั้งหมด
    await fetchAndScheduleNotifications(userId); // ตั้งค่าการแจ้งเตือนใหม่
    print("✅ Notifications updated successfully!");
  });
}

}
