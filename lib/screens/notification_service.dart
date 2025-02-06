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
  bool _isCheckingSkippedMedications = false; // เพิ่ม Flag
  Timer? _debounceTimer;

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

Future<void> checkAndRecordSkippedMedications(String userId) async {
  if (_isCheckingSkippedMedications) {
    print('⏳ กำลังตรวจสอบอยู่แล้ว ไม่ต้องเรียกซ้ำ');
    return;
  }

  _isCheckingSkippedMedications = true;
  print('🔍 กำลังตรวจสอบยาที่ไม่ได้ทาน');

  try {
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final snapshot = await FirebaseFirestore.instance
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final medicationId = doc.id;
      final rfidTag = data['RFID_tag'];
      final newNotificationTimes = List<String>.from(data['Notification_times'] ?? []);
      final lastSkipCheck = (data['Last_skip_check'] as Timestamp?)?.toDate() ?? DateTime(2000);

      // ✅ ดึงรายการ Skip ทั้งหมดของวันนี้
      final historySnapshot = await FirebaseFirestore.instance
          .collection('Medication_history')
          .where('User_id', isEqualTo: userId)
          .where('Medication_id', isEqualTo: medicationId)
          .where('Date', isEqualTo: formattedDate)
          .where('Status', isEqualTo: 'Skip')
          .get();

      List<String> existingSkippedTimes = historySnapshot.docs.map((doc) => doc['Scheduled_time'] as String).toList();

      // ✅ หาว่าเวลาที่มีอยู่ใน `Medication_history` แต่ไม่มีใน `newNotificationTimes`
      final timesToRemove = existingSkippedTimes.where((time) => !newNotificationTimes.contains(time)).toList();

      // 🗑 ลบ Skip ของเวลาที่ไม่มีใน Notification_times ใหม่
      if (timesToRemove.isNotEmpty) {
        print('🗑 ลบ Skip ที่ไม่อยู่ในเวลาปัจจุบัน: $timesToRemove');

        for (String time in timesToRemove) {
          final oldSkipRecords = await FirebaseFirestore.instance
              .collection('Medication_history')
              .where('User_id', isEqualTo: userId)
              .where('Medication_id', isEqualTo: medicationId)
              .where('Scheduled_time', isEqualTo: time)
              .where('Date', isEqualTo: formattedDate)
              .where('Status', isEqualTo: 'Skip')
              .get();

          for (var record in oldSkipRecords.docs) {
            await FirebaseFirestore.instance.collection('Medication_history').doc(record.id).delete();
            print('🗑 ลบ Skip สำหรับเวลา $time แล้ว');
          }
        }
      }

      // ✅ เพิ่ม Skip ให้กับเวลาที่ถูกเพิ่มใหม่
      for (String time in newNotificationTimes) {
        final timeParts = time.split(':');
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final difference = now.difference(scheduledDateTime);

        if (difference.inMinutes <= 300) {  
          print('⏳ ยังไม่ถึงเวลาตรวจสอบ Skip สำหรับ $time');
          continue;
        }

        // ✅ เช็คว่ามีการบันทึก Skip ไปแล้วหรือยัง
        if (existingSkippedTimes.contains(time)) {
          print('✅ มีการบันทึก Skip แล้วสำหรับ $time, ไม่ต้องบันทึกซ้ำ');
          continue;
        }

        // ✅ เพิ่ม Skip สำหรับเวลาใหม่
        print('⚠️ บันทึก Skip สำหรับเวลาใหม่ $time');
        await FirebaseFirestore.instance.collection('Medication_history').add({
          'User_id': userId,
          'RFID_tag': rfidTag,
          'Medication_id': medicationId,
          'Scheduled_time': time,
          'Date': formattedDate,
          'Status': 'Skip',
          'AutoSave': true,
          'mark': false,
          'Intake_time': FieldValue.serverTimestamp(),
        });

        // ✅ อัปเดต Last_skip_check หลังจากบันทึก Skip ใหม่
        await FirebaseFirestore.instance.collection('Medications').doc(medicationId).update({
          'Last_skip_check': FieldValue.serverTimestamp(),
        });
      }
    }
  } catch (e) {
    print('❌ Error checking skipped medications: $e');
  } finally {
    _isCheckingSkippedMedications = false;
  }
}


void listenToMedicationChanges(String userId) {
  print('🔍 Listening for medication changes for User ID: $userId');

  FirebaseFirestore.instance
      .collection('Medications')
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .listen((snapshot) async {
    if (snapshot.docChanges.isEmpty) {
      print('🔄 No actual changes detected, skipping...');
      return;
    }

    bool shouldCheckSkip = false;

    for (var change in snapshot.docChanges) {
      final docData = change.doc.data() as Map<String, dynamic>?;

      if (docData == null) continue;

      // เช็กว่าเปลี่ยน Notification_times หรือเปล่า
      if (change.type == DocumentChangeType.modified) {
        final newTimes = List<String>.from(docData['Notification_times'] ?? []);
        final lastUpdated = (docData['Updated_at'] as Timestamp?)?.toDate();

        // ถ้ามีการเปลี่ยนแปลงเวลา ให้ข้ามการเช็ก Skip
        if (lastUpdated != null &&
            DateTime.now().difference(lastUpdated).inMinutes < 2) {
          print('🛑 มีการอัปเดตยา (เปลี่ยนเวลา) ข้ามการเช็ก Skip');
          return;
        }
      }

      shouldCheckSkip = true;
    }

    if (shouldCheckSkip) {
      await checkAndRecordSkippedMedications(userId);
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
    }
  }, onError: (error) {
    print('❌ CRITICAL ERROR in medication changes listener');
    print('Error: $error');
  });
}

Future<void> removeOldSkips(String userId, String medicationId, List<String> oldTimes, List<String> newTimes) async {
  final now = DateTime.now();
  final formattedDate =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  // หาค่าเวลาเก่าที่ไม่ได้อยู่ในลิสต์ใหม่
  final timesToRemove = oldTimes.where((time) => !newTimes.contains(time)).toList();

  if (timesToRemove.isEmpty) return; // ถ้าไม่มีเวลาเก่าที่ต้องลบ ก็ไม่ต้องทำอะไร

  print('🗑 กำลังลบ Skip เก่าที่ไม่อยู่ในเวลาปัจจุบัน: $timesToRemove');

  for (String time in timesToRemove) {
    final existingRecords = await FirebaseFirestore.instance
        .collection('Medication_history')
        .where('User_id', isEqualTo: userId)
        .where('Medication_id', isEqualTo: medicationId)
        .where('Scheduled_time', isEqualTo: time)
        .where('Date', isEqualTo: formattedDate)
        .where('Status', isEqualTo: 'Skip')
        .get();

    for (var doc in existingRecords.docs) {
      await FirebaseFirestore.instance.collection('Medication_history').doc(doc.id).delete();
      print('🗑 ลบ Skip สำหรับ $time แล้ว');
    }
  }
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