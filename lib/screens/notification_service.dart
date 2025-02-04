import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/main.dart';
import 'package:tagtime_medicare/screens/medicine_detail_page.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/scheduler.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(iOS: iOSSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        print('🔔 Notification clicked!');
        _handleNotificationClick(response.payload);
      },
    );

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📩 App opened from terminated state via notification!');
        _handleNotificationClick(jsonEncode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📩 Notification clicked while app was open!');
      _handleNotificationClick(jsonEncode(message.data));
    });

    FirebaseMessaging.onMessage.listen((message) {
      print('🔔 Notification received while app is in foreground');
      _showLocalNotification(message);
    });

    print('✅ NotificationService initialized');
  }

  void _handleNotificationClick(String? payload) async {
    print('🔔 Notification clicked with payload: $payload');

    if (payload == null) {
      print('❌ No payload in notification');
      _showSnackBar('Error: No medication data found');
      return;
    }

    try {
      final payloadData = json.decode(payload);
      print('📦 Decoded payload: $payloadData');

      if (payloadData == null) {
        print('❌ Invalid payload format');
        _showSnackBar('Error: Invalid notification data');
        return;
      }

      final String? rfidUID = payloadData['rfidUID'];
      final String? userId = payloadData['user_id'];

      if (rfidUID == null || userId == null) {
        print('❌ Missing required data in payload');
        _showSnackBar('Error: Missing medication details');
        return;
      }

      // ดึงข้อมูลยา
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('RFID_tag', isEqualTo: rfidUID)
          .where('user_id', isEqualTo: userId)
          .get();

      print('📄 Found ${medsSnapshot.docs.length} medications');

      if (medsSnapshot.docs.isEmpty) {
        print('❌ No medication found');
        _showSnackBar('Error: Medication not found');
        return;
      }

      final medicineData = medsSnapshot.docs.first.data();
      print('✅ Navigating to medicine detail with data: $medicineData');

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MedicineDetailPage(
            medicineData: medicineData,
            rfidUID: rfidUID,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error handling notification: $e');
      _showSnackBar('Error: Could not load medication details');
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String rfidUID,
    required String userId,
  }) async {
    try {
      print('🔔 Scheduling notification for RFID: $rfidUID');

      final tz.Location localTZ = tz.getLocation('Asia/Bangkok');
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(scheduledDate, localTZ);

      final payload = json.encode({
        'rfidUID': rfidUID,
        'user_id': userId,
      });

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
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
    }
  }

  void checkAndRecordSkippedMedications(String userId) {
  print('🔍 เริ่มตรวจสอบยาที่ไม่ได้ทาน');
  
  FirebaseFirestore.instance
      .collection('Medications')
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .listen((snapshot) async {
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
      final rfidTag = data['RFID_tag'];
      final medicationId = doc.id;
      
      for (String time in notificationTimes) {
        await _checkAndRecordSkip(
          userId: userId,
          rfidTag: rfidTag,
          medicationId: medicationId,
          scheduledTime: time,
        );
      }
    }
  });
}

Future<void> _checkAndRecordSkip({
  required String userId,
  required String rfidTag,
  required String medicationId,
  required String scheduledTime,
}) async {
  // รับวันที่ปัจจุบัน
  final today = DateTime.now();
  final formattedDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  
  // แปลงเวลาที่กำหนด
  final timeParts = scheduledTime.split(':');
  final scheduledDateTime = DateTime(
    today.year,
    today.month,
    today.day,
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
  );
  
  // ตรวจสอบว่าผ่านไป 2 ชั่วโมงหรือยัง
  final difference = today.difference(scheduledDateTime);
  if (difference.inMinutes <= 120) {
    print('⏳ ยังไม่ถึงเวลาบันทึก Skip สำหรับ $scheduledTime');
    return;
  }
  
  // ตรวจสอบว่ามีการบันทึกไปแล้วหรือไม่
  final existingRecord = await FirebaseFirestore.instance
      .collection('Medication_history')
      .where('User_id', isEqualTo: userId)
      .where('RFID_tag', isEqualTo: rfidTag)
      .where('Medication_id', isEqualTo: medicationId)
      .where('Scheduled_time', isEqualTo: scheduledTime)
      .where('Date', isEqualTo: formattedDate)
      .get();
      
  if (existingRecord.docs.isNotEmpty) {
    print('✅ มีการบันทึกข้อมูลแล้วสำหรับ $scheduledTime');
    return;
  }
  
  // บันทึกเป็น Skip
  print('⚠️ บันทึก Skip สำหรับ $scheduledTime');
  await FirebaseFirestore.instance.collection('Medication_history').add({
    'User_id': userId,
    'RFID_tag': rfidTag,
    'Medication_id': medicationId,
    'Scheduled_time': scheduledTime,
    'Date': formattedDate,
    'Status': 'Skip',
    'AutoSave': true,
    'mark': false,
    'Intake_time': Timestamp.now(),
  });
}

  void listenToMedicationChanges(String userId) {
    print('🔍 Listening for medication changes for User ID: $userId');

  checkAndRecordSkippedMedications(userId);

    FirebaseFirestore.instance
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      print('🚨 FIREBASE CHANGE DETECTED 🚨');
      print('📊 Total documents changed: ${snapshot.docs.length}');

      await cancelAllNotifications();
      print('🧹 Cancelled all previous notifications');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final medicationName = data['M_name'] ?? 'Unknown';
        final notificationTimes =
            List<String>.from(data['Notification_times'] ?? []);
        final startDate = (data['Start_date'] as Timestamp).toDate();
        final endDate = (data['End_date'] as Timestamp).toDate();
        final now = DateTime.now();
        final rfidUID = data['RFID_tag'] ?? 'N/A';

        if (now.isBefore(startDate) || now.isAfter(endDate)) {
          print('⏭️ Skipping $medicationName: Outside valid date range');
          continue;
        }

        for (String time in notificationTimes) {
          try {
            final timeParts = time.split(':');
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);

            if (hour == null || minute == null) {
              print('⚠️ Invalid time format: $time');
              continue;
            }

            final DateTime scheduledDate =
                DateTime(now.year, now.month, now.day, hour, minute);

            final adjustedDate = scheduledDate.isBefore(now)
                ? scheduledDate.add(const Duration(days: 1))
                : scheduledDate;

            await scheduleNotification(
              id: (medicationName + time).hashCode.abs() % 100000,
              title: '💊 Medication Reminder',
              body: 'Time to take $medicationName',
              scheduledDate: adjustedDate,
              rfidUID: rfidUID,
              userId: userId,
            );
          } catch (e) {
            print('❌ Error scheduling notification for $medicationName: $e');
          }
        }
      }
    }, onError: (error) {
      print('❌ CRITICAL ERROR in medication changes listener');
      print('Error: $error');
    });
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
