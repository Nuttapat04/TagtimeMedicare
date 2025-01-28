import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tagtime_medicare/main.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
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
  body: 'Time to take $medicationName',
  scheduledDate: adjustedDate,
  payload: json.encode({
    'M_name': medicationName,
    'RFID_tag': data['RFID_tag'] ?? 'N/A',  // ใช้ข้อมูลจาก data แทน rfidUID
    'user_id': userId,
  }),
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

  FirebaseFirestore.instance
      .collection('Medications')
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .listen((snapshot) async {
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final medicationName = data['M_name'] ?? 'Unknown';
      final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
      final startDate = (data['Start_date'] as Timestamp).toDate();
      final endDate = (data['End_date'] as Timestamp).toDate();
      final rfidUID = data['rfidUID'] ?? 'N/A';

      // ✅ ตรวจสอบว่าอยู่ในช่วงวันที่กำหนด
      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        continue;
      }

      // ✅ เช็คเวลาปัจจุบันกับ notificationTimes
      for (String time in notificationTimes) {
        final hour = int.parse(time.split(':')[0]);
        final minute = int.parse(time.split(':')[1]);

        final DateTime scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // ✅ เช็คว่าถึงเวลายาแล้ว (±1 นาที)
        if (scheduledTime.isAfter(now.subtract(const Duration(minutes: 1))) &&
            scheduledTime.isBefore(now.add(const Duration(minutes: 1)))) {
          print("🔔 Time to take $medicationName!");

          // ✅ Navigate to MedicineDetailPage
          Navigator.push(
            navigatorKey.currentState!.context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailPage(
                medicineData: data,
                rfidUID: rfidUID,
              ),
            ),
          );

          break;
        }
      }
    }
  });
}

}
