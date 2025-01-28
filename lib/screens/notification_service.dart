import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/main.dart';
import 'package:tagtime_medicare/screens/local_storage.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // 1. ตั้งค่า iOS settings
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 2. รวม settings ทั้งหมด
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: iOSSettings,
    );

    // 3. Initialize พร้อม callback
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // ใส่ log เพื่อ debug
        print('🔔 onDidReceiveNotificationResponse called');
        print('Payload: ${response.payload}');

        // เรียกใช้ handler
        _handleNotificationResponse(response);
      },
    );

    print('✅ Notification service initialized');
  }

  Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    print('🔔 Notification tapped! Payload: ${response.payload}');

    if (response.payload != null) {
      try {
        // เช็ค Firebase current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print('❌ No Firebase user logged in');
          _navigateToWelcome();
          return;
        }

        // เช็ค user_id จาก LocalStorage
        final storedUserId = await LocalStorage.getData('user_id');
        if (storedUserId == null || storedUserId != currentUser.uid) {
          print('❌ Stored user ID mismatch or not found');
          print('Stored ID: $storedUserId');
          print('Current Firebase ID: ${currentUser.uid}');
          _navigateToWelcome();
          return;
        }

        final payloadMap = json.decode(response.payload!);
        final medicineName = payloadMap['M_name'];
        final rfidUID = payloadMap['RFID_tag'];

        // ค้นหายาที่ตรงกับ user_id ปัจจุบัน
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Medications')
            .where('M_name', isEqualTo: medicineName)
            .where('user_id', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final medicineData = querySnapshot.docs.first.data();

          // เช็คว่ายานี้เป็นของ user คนปัจจุบันจริงๆ
          if (medicineData['user_id'] != currentUser.uid) {
            print('❌ Medicine belongs to different user');
            return;
          }

          print('✅ Found medicine data for current user');
          await Future.delayed(const Duration(milliseconds: 500));

          if (navigatorKey.currentState != null) {
            print('🚀 Navigating to medicine detail page...');
            navigatorKey.currentState!.pushNamed(
              '/medicine_detail',
              arguments: {
                'medicineData': medicineData,
                'rfidUID': rfidUID,
              },
            );
            print('✅ Navigation completed');
          } else {
            print('❌ Navigator is not available');
          }
        } else {
          print('❌ No medicine found for current user');
        }
      } catch (e, stack) {
        print('❌ Error handling notification: $e');
        print('Stack trace: $stack');
        _navigateToWelcome();
      }
    } else {
      print('⚠️ No payload in notification');
    }
  }

// เพิ่มเมธอดสำหรับ navigate ไปหน้า welcome
  void _navigateToWelcome() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

  Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String payload,
}) async {
  try {
    // ตรวจสอบ payload
    final decodedPayload = json.decode(payload);
    if (!decodedPayload.containsKey('M_name') ||
        !decodedPayload.containsKey('RFID_tag')) {
      throw FormatException('Invalid payload format');
    }

    // สร้าง scheduledTime จาก scheduledDate
    final tz.Location localTZ = tz.getLocation('Asia/Bangkok');
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(scheduledDate, localTZ);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,  // ใช้ scheduledTime ที่สร้างขึ้น
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
          categoryIdentifier: 'medicine_reminder',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  } catch (e) {
    print('❌ Error scheduling notification: $e');
    print('Invalid payload: $payload');
    return;
  }
}
  void listenToMedicationChanges(String userId) {
    FirebaseFirestore.instance
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      await cancelAllNotifications();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final medicationName = data['M_name'] ?? 'Unknown';
        final notificationTimes =
            List<String>.from(data['Notification_times'] ?? []);
        final startDate = (data['Start_date'] as Timestamp).toDate();
        final endDate = (data['End_date'] as Timestamp).toDate();
        final now = DateTime.now();
        final rfidUID = data['RFID_tag'] ?? 'N/A';

        print('📦 Processing medication:');
        print('Name: $medicationName');
        print('RFID: $rfidUID');
        print('User ID: $userId');

        if (now.isBefore(startDate) || now.isAfter(endDate)) {
          continue;
        }

        for (String time in notificationTimes) {
          try {
            // ทำความสะอาดข้อมูลเวลาก่อน
            String cleanTime = time.replaceAll(RegExp(r'[^\d:]'), '');
            List<String> timeParts = cleanTime.split(':');

            if (timeParts.length != 2) {
              print('⚠️ Invalid time format: $time');
              continue;
            }

            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);

            if (hour == null || minute == null) {
              print('⚠️ Invalid time values: hour=$hour, minute=$minute');
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

            // สร้าง payload
            final payload = json.encode({
              'M_name': medicationName,
              'RFID_tag': rfidUID,
              'user_id': userId,
            });

            print('📩 Creating notification with payload: $payload');

            await scheduleNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: '💊 Medication Reminder',
              body: 'Time to take $medicationName',
              scheduledDate: adjustedDate,
              payload: payload,
            );

            print(
                '✅ Notification scheduled for $medicationName at $adjustedDate');
          } catch (e) {
            print('❌ Error scheduling notification for time $time: $e');
            continue;
          }
        }
      }
    });
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }
}
