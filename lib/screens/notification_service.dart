import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          print('🔔 Notification tapped: $payload');
        }
      },
    );
  }

  // ✅ ทดสอบแจ้งเตือนทันที
  Future<void> testImmediateNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        '🔔 Test Notification',
        'This is a test notification sent immediately.',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'TestPayload',
      );
      print('✅ Immediate test notification sent.');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // ✅ ตั้งค่าแจ้งเตือนล่วงหน้า
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    print('📅 Scheduling notification for: $title at $scheduledDate (Local TZ)');

    final tz.Location localTZ = tz.getLocation('Asia/Bangkok');
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(scheduledDate, localTZ);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      print('✅ Notification scheduled successfully for $title at $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  // ✅ ยกเลิกแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('✅ All notifications cancelled successfully.');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  // ✅ ตรวจสอบว่ามียาถูกแก้ไขใน Firebase แล้วตั้งค่าแจ้งเตือนใหม่
  void listenToMedicationChanges(String userId) {
    FirebaseFirestore.instance
        .collection('Medications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      print('🔄 Detected changes in medication data for user: $userId');

      // ยกเลิกแจ้งเตือนเก่าทั้งหมด
      await cancelAllNotifications();

      // ตั้งแจ้งเตือนใหม่
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final medicationName = data['M_name'] ?? 'Unknown';
        final notificationTimes = List<String>.from(data['Notification_times'] ?? []);
        final startDate = (data['Start_date'] as Timestamp).toDate();
        final endDate = (data['End_date'] as Timestamp).toDate();
        final now = DateTime.now();

        if (now.isBefore(startDate) || now.isAfter(endDate)) {
          print('⏭️ Skipping $medicationName: Out of date range.');
          continue;
        }

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

          await scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: '💊 Medication Reminder',
            body: 'Time to take $medicationName.',
            scheduledDate: adjustedDate,
            payload: medicationName,
          );
          print('✅ Notification scheduled for $medicationName at $adjustedDate');
        }
      }
    });
  }
}
