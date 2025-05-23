import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_alert_detail_screen.dart';
import 'notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportNotificationScreen extends StatefulWidget {
  final String farmId;

  const ReportNotificationScreen({super.key, required this.farmId});

  @override
  _ReportNotificationScreenState createState() => _ReportNotificationScreenState();
}

class _ReportNotificationScreenState extends State<ReportNotificationScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'Notifications Alerts': 'Mga Alerto sa Notipikasyon',
      'No notifications yet': 'Wala pang mga notipikasyon',
      'Urgent': 'Agaran',
      'Normal': 'Normal',
      'Location': 'Lokasyon',
      'Owner': 'May-ari',
      'Timestamp': 'Oras',
      'New': 'Bago',
    },
    'Bisaya': {
      'Notifications Alerts': 'Mga Alerto sa Pahibalo',
      'No notifications yet': 'Wala pay mga pahibalo',
      'Urgent': 'Dinalian',
      'Normal': 'Normal',
      'Location': 'Lokasyon',
      'Owner': 'Tag-iya',
      'Timestamp': 'Oras',
      'New': 'Bag-o',
    },
  };

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  String _getTranslatedText(String key) {
    if (_selectedLanguage == 'English') {
      return key;
    }
    return _translations[_selectedLanguage]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _notificationManager.resetBadgeCount();
    _loadLanguagePreference();
  }

  Stream<QuerySnapshot> _getAlertsStream() {
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('farmId', isEqualTo: widget.farmId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _markAlertAsRead(String alertId) async {
    await FirebaseFirestore.instance
        .collection('alerts')
        .doc(alertId)
        .update({'isNew': false});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF40C4FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                _getTranslatedText('Notifications Alerts'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40C4FF),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAlertsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final alerts = snapshot.data?.docs ?? [];

                  if (alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: const Color(0xFF40C4FF).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getTranslatedText('No notifications yet'),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF40C4FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final alertDoc = alerts[index];
                      final alert = alertDoc.data() as Map<String, dynamic>;
                      final alertId = alertDoc.id;
                      final detection = alert['detection'] as String;
                      final timestamp = alert['timestamp'] as Timestamp;
                      final formattedTimestamp = DateFormat('MMM d, y h:mm a').format(timestamp.toDate());
                      final requiresImmediateAction = alert['requiresImmediateAction'] as bool;
                      final isNew = alert['isNew'] as bool? ?? false;

                      return GestureDetector(
                        onTap: () async {
                          await _markAlertAsRead(alertId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationAlertDetailScreen(alert: alert, alertId: alertId),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isNew ? const Color(0xFF40C4FF).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF40C4FF).withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert['farmName'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF40C4FF),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: requiresImmediateAction ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getTranslatedText(requiresImmediateAction ? 'Urgent' : 'Normal'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: requiresImmediateAction ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                detection,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: requiresImmediateAction ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_getTranslatedText('Location')}: ${alert['locationDescription']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getTranslatedText('Owner')}: ${alert['ownerFirstName']} ${alert['ownerLastName']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_getTranslatedText('Timestamp')}: $formattedTimestamp',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (isNew)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF40C4FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getTranslatedText('New'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

