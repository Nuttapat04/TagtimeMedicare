// notification_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/main.dart';
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

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: iOSSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('🔔 onDidReceiveNotificationResponse called');
        print('Payload: ${response.payload}');
        _handleNotificationResponse(response);
      },
    );

    print('✅ Notification service initialized');
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    print('🔔 Notification tapped! Payload: ${response.payload}');

    if (response.payload != null) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print('❌ No Firebase user logged in');
          _navigateToWelcome();
          return;
        }

        final payloadMap = json.decode(response.payload!);
        final medicineName = payloadMap['M_name'];
        final rfidUID = payloadMap['RFID_tag'];

        final querySnapshot = await FirebaseFirestore.instance
            .collection('Medications')
            .where('M_name', isEqualTo: medicineName)
            .where('user_id', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final medicineData = querySnapshot.docs.first.data();

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
      if (scheduledDate.isBefore(DateTime.now())) {
        print('⚠️ Cannot schedule notification in the past. Scheduled Date: $scheduledDate');
        return;
      }

      final decodedPayload = json.decode(payload);
      if (!decodedPayload.containsKey('M_name') ||
          !decodedPayload.containsKey('RFID_tag')) {
        throw FormatException('Invalid payload format');
      }

      final tz.Location localTZ = tz.getLocation('Asia/Bangkok');
      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(scheduledDate, localTZ);

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
      print('Invalid payload: $payload');
      return;
    }
  }

  void listenToMedicationChanges(String userId) {
    print('🔍 Starting medication changes listener for User ID: $userId');

    FirebaseFirestore.instance
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      print('🚨 FIREBASE CHANGE DETECTED 🚨');
      print('📊 Total documents changed: ${snapshot.docChanges.length}');

      for (var change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            print('➕ Document ADDED: ${change.doc.id}');
            break;
          case DocumentChangeType.modified:
            print('🔄 Document MODIFIED: ${change.doc.id}');
            break;
          case DocumentChangeType.removed:
            print('➖ Document REMOVED: ${change.doc.id}');
            break;
        }
      }

      await cancelAllNotifications();
      print('🧹 Cancelled all previous notifications');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final medicationName = data['M_name'] ?? 'Unknown';
        final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
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

            final payload = json.encode({
              'M_name': medicationName,
              'RFID_tag': rfidUID,
              'user_id': userId,
            });

            final notificationId = (medicationName + time).hashCode.abs() % 100000;

            print('📅 Scheduling notification:');
            print('🆔 Notification ID: $notificationId');
            print('💊 Medication: $medicationName');
            print('⏰ Scheduled Time: $adjustedDate');

            await scheduleNotification(
              id: notificationId,
              title: '💊 Medication Reminder',
              body: 'Time to take $medicationName',
              scheduledDate: adjustedDate,
              payload: payload,
            );
          } catch (e) {
            print('❌ Error scheduling notification for $medicationName: $e');
            continue;
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
}