import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './report-detail-screen.dart';
import 'fisher_report_notification_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'notification_manager.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';

class FisherReportsScreen extends StatefulWidget {
  final String farmId;
  final Function(bool) updateBadgeStatus;

  const FisherReportsScreen({
    super.key,
    required this.farmId,
    required this.updateBadgeStatus
  });

  @override
  _FisherReportsScreenState createState() => _FisherReportsScreenState();
}

class _FisherReportsScreenState extends State<FisherReportsScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  int _badgeCount = 0;
  bool _isDisposed = false;
  bool _hasNewAlerts = false;
  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'REPORTS': 'ULAT',
      'No reports found.': 'WALANG ULAT.',
      'STATUS': 'STATUS',
      'FARM NAME': 'ISDAAN',
      'LOCATION': 'LOKASYON',
      'DATE/TIME': 'PETSA',
      'DETECTION': 'PAGTUKLAS',
      'Unknown Farm': 'DI-KILALA',
      'Location unavailable': 'WALANG LUGAR',
      'Fetching location...': 'KUMUKUHA...',
    },
    'Bisaya': {
      'REPORTS': 'REPORT',
      'No reports found.': 'WALAY REPORT.',
      'STATUS': 'STATUS',
      'FARM NAME': 'UMAHAN',
      'LOCATION': 'LOKASYON',
      'DATE/TIME': 'PETSA',
      'DETECTION': 'DETEKSYON',
      'Unknown Farm': 'WALA MAILHI',
      'Location unavailable': 'WAY DAPIT',
      'Fetching location...': 'GAKUHA...',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _notificationManager.initialize().then((_) {
      if (!_isDisposed) {
        _listenForNewReports();
        _listenForNewAlerts();
      }
    });
  }

  void _listenForNewReports() {
    _notificationManager.getReportsStream(widget.farmId).listen((snapshot) {
      if (!_isDisposed && mounted) {
        if (snapshot.docChanges.isNotEmpty) {
          setState(() {
            _badgeCount = _notificationManager.getBadgeCount();
          });
        }
      }
    });
  }

  void _listenForNewAlerts() {
    FirebaseFirestore.instance
        .collection('alerts')
        .where('farmId', isEqualTo: widget.farmId)
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen((alertSnapshot) {
      if (mounted) {
        setState(() {
          _hasNewAlerts = alertSnapshot.docs.isNotEmpty;
        });
      }
    });
  }

  Future<void> _markAlertsAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('alerts')
        .where('farmId', isEqualTo: widget.farmId)
        .where('isNew', isEqualTo: true)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isNew': false});
    }

    await batch.commit();
    setState(() {
      _hasNewAlerts = false;
    });
  }

  Future<String> _getLocationDescription(List<dynamic>? coordinates) async {
    if (coordinates != null && coordinates.length == 2) {
      final lat = coordinates[0];
      final lng = coordinates[1];

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String street = place.street ?? '';
          String locality = place.locality ?? '';
          return '${street.isNotEmpty ? '$street, ' : ''}$locality'.trim();
        }
      } catch (e) {
        print('Error fetching location details: $e');
      }
    }
    return _getTranslatedText('Location unavailable');
  }

  Stream<QuerySnapshot> _getReportsStream() {
    return _notificationManager.getReportsStream(widget.farmId);
  }

  void _navigateToDetail(BuildContext context, DocumentSnapshot report) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(report.id)
        .update({'isNew': false});

    if (report.data() != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: report),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Report data is not available')),
      );
    }
  }

  Widget _buildStatusIndicator(bool isReplied, String detection) {
    if (isReplied) {
      return const Icon(Icons.check_circle, color: Colors.blue, size: 16);
    } else {
      final color = detection.toLowerCase().contains('not likely detected')
          ? Colors.green
          : Colors.red;
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            showBadge: _hasNewAlerts,
            badgeContent: const Text(
              '!',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () async {
                await _markAlertsAsRead();
                setState(() {
                  _hasNewAlerts = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportNotificationScreen(farmId: widget.farmId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _getTranslatedText('REPORTS'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildTableHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(_getTranslatedText('No reports found.'), style: const TextStyle(fontSize: 16)));
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final data = report.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp?;
                      final dateTime = timestamp != null
                          ? DateFormat('MM/dd/yyyy\nh:mm a').format(timestamp.toDate())
                          : 'N/A';
                      final detection = data['detection'] ?? 'Unknown';
                      final realtimeLocation = data['realtime_location'] as List<dynamic>?;
                      final isReplied = data['isReplied'] as bool? ?? false;

                      return FutureBuilder<String>(
                        future: _getLocationDescription(realtimeLocation),
                        builder: (context, locationSnapshot) {
                          final locationDescription = locationSnapshot.data ?? _getTranslatedText('Fetching location...');

                          return GestureDetector(
                            onTap: () => _navigateToDetail(context, report),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF40C4FF)),
                                borderRadius: BorderRadius.circular(8),
                                color: data['isNew'] == true ? Colors.blue[50] : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: _buildStatusIndicator(isReplied, detection),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _getTranslatedText(data['farmName'] ?? 'Unknown Farm'),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              locationDescription,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              dateTime,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              detection.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: detection.toLowerCase().contains('not likely detected')
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _getTranslatedText('STATUS'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('FARM NAME'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('LOCATION'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('DATE/TIME'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('DETECTION'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
