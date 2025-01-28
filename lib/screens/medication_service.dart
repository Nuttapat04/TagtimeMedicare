// medication_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tagtime_medicare/main.dart';
import 'package:tagtime_medicare/screens/notification_service.dart';

class MedicationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> fetchAndScheduleNotifications(String userId) async {
    try {
      print('🚀 Starting medication notification setup for User ID: $userId');

      final QuerySnapshot medsSnapshot = await firestore
          .collection('Medications')
          .where('user_id', isEqualTo: userId)
          .get();

      print('📊 Total medications found: ${medsSnapshot.docs.length}');

      if (medsSnapshot.docs.isEmpty) {
        print('⚠️ No medications found for this user');
        return;
      }

      await NotificationService().cancelAllNotifications();
      print('🧹 Cancelled all previous notifications');

      final now = DateTime.now();
      bool anyNotificationScheduled = false;

      for (var doc in medsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final medicationName = data['M_name'] ?? 'Unknown Medication';
        final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
        final startDate = (data['Start_date'] as Timestamp).toDate();
        final endDate = (data['End_date'] as Timestamp).toDate();
        final rfidTag = data['RFID_tag'] ?? 'N/A';

        print('💊 Medication Details:');
        print('   Name: $medicationName');
        print('   RFID Tag: $rfidTag');
        print('   Start Date: $startDate');
        print('   End Date: $endDate');
        print('   Notification Times: $notificationTimes');

        if (now.isBefore(startDate) || now.isAfter(endDate)) {
          print('⏭️ Skipping $medicationName: Outside valid date range');
          continue;
        }

        for (String time in notificationTimes) {
          try {
            final timeParts = time.split(':');
            if (timeParts.length != 2) {
              print('⚠️ Invalid time format: $time');
              continue;
            }

            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);

            if (hour == null || minute == null) {
              print('⚠️ Cannot parse time: $time');
              continue;
            }

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

            final notificationId = _generateUniqueId(medicationName, time);

            final payload = json.encode({
              'M_name': medicationName,
              'RFID_tag': rfidTag,
              'user_id': userId,
            });

            await NotificationService().scheduleNotification(
              id: notificationId,
              title: '💊 Medication Reminder',
              body: 'Time to take $medicationName',
              scheduledDate: adjustedDate,
              payload: payload,
            );

            print('✅ Notification scheduled for $medicationName at $adjustedDate');
            anyNotificationScheduled = true;

          } catch (e) {
            print('❌ Error processing notification for $medicationName: $e');
          }
        }
      }

      if (!anyNotificationScheduled) {
        print('⚠️ No notifications could be scheduled');
      } else {
        print('🎉 All medication notifications set up successfully');
      }

    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR in medication notification setup');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  int _generateUniqueId(String medicineName, String time) {
    return (medicineName + time).hashCode.abs() % 100000;
  }
}