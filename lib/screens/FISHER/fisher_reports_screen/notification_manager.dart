import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int _badgeCount = 0;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Load the initial badge count from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _badgeCount = prefs.getInt('badgeCount') ?? 0;
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'farm_reports_channel',
      'Farm Reports Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );

    // Increment badge count and save to SharedPreferences
    _badgeCount++;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badgeCount', _badgeCount);
  }

  int getBadgeCount() {
    return _badgeCount;
  }

  Future<void> resetBadgeCount() async {
    _badgeCount = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badgeCount', _badgeCount);
  }

  Stream<QuerySnapshot> getReportsStream(String farmId) {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: farmId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

