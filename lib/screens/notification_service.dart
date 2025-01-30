import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
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
    if (payload == null) {
      print('❌ No payload found in notification.');
      return;
    }

    try {
      final payloadData = json.decode(payload);
      final String? rfidUID = payloadData['rfidUID'];
      final String? userId = payloadData['user_id'];

      if (rfidUID != null && userId != null) {
        print('🔍 Fetching medication data for RFID: $rfidUID');

        final medsSnapshot = await FirebaseFirestore.instance
            .collection('Medications')
            .where('RFID_tag', isEqualTo: rfidUID)
            .where('user_id', isEqualTo: userId)
            .get();

        if (medsSnapshot.docs.isNotEmpty) {
          final medicineData = medsSnapshot.docs.first.data();
          print('✅ Found medicine: $medicineData');

          navigatorKey.currentState?.pushNamed(
            '/medicine_detail',
            arguments: {
              'medicineData': medicineData,
              'rfidUID': rfidUID,
            },
          );
          print('✅ Navigation completed');
        } else {
          print('❌ No medicine found for RFID: $rfidUID');
          _showSnackBar('No medicine found for this RFID tag');
        }
      } else {
        print('❌ Missing RFID or user_id in payload.');
      }
    } catch (e) {
      print('❌ Error handling notification response: $e');
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

  void listenToMedicationChanges(String userId) {
    print('🔍 Listening for medication changes for User ID: $userId');

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
