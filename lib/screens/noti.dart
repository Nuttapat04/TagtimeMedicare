import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MedicationNotificationPage extends StatefulWidget {
  @override
  _MedicationNotificationPageState createState() =>
      _MedicationNotificationPageState();
}

class _MedicationNotificationPageState
    extends State<MedicationNotificationPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    initializeNotifications();
    fetchAndScheduleNotifications();
  }

  void initializeNotifications() async {
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification clicked: $payload')),
        );
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final payload = notificationResponse.payload;
        if (payload != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notification clicked: $payload')),
          );
        }
      },
    );
  }

  Future<void> fetchAndScheduleNotifications() async {
    final medications = await firestore.collection('Medications').get();

    for (var doc in medications.docs) {
      final data = doc.data();
      final notificationTimes = List.from(data['Notification_times'] ?? []);
      final medicationName = data['M_name'] ?? "Unknown";

      for (String time in notificationTimes) {
        scheduleNotification(time, medicationName);
      }
    }
  }

  void scheduleNotification(String time, String medicationName) async {
    final hour = int.parse(time.split(':')[0]);
    final minute = int.parse(time.split(':')[1]);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Unique ID for notification
      'Time to take your medication',
      'It\'s time to take $medicationName.', // ใช้ interpolation อย่างถูกต้อง
      scheduledTime.isBefore(now)
          ? scheduledTime.add(Duration(days: 1))
          : scheduledTime,
      NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Notifications'),
      ),
      body: StreamBuilder(
        stream: firestore.collection('Medications').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final medications = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final data = medications[index].data() as Map<String, dynamic>;
              final name = data['M_name'] ?? "Unknown";
              final times = List.from(data['Notification_times'] ?? []);

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('Times: ${times.join(', ')}'),
                  trailing: IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => fetchAndScheduleNotifications(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
