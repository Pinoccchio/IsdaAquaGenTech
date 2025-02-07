import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportDetailScreen extends StatefulWidget {
  final DocumentSnapshot? report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String _locationDescription = 'Fetching location...';
  bool _isSendingAlert = false;
  String _timestamp = '';
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String _selectedLanguage = 'English';
  bool? _reportToBFAR; // Added state variable for BFAR selection
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'REPORT': 'ULAT',
      'ORGANISM': 'ORGANISMO',
      'FARM NAME': 'PANGALAN NG SAKAHAN',
      'OWNER': 'MAY-ARI',
      'CONTACT NUMBER': 'NUMERO NG CONTACT',
      'FEED TYPES': 'MGA URI NG PAGKAIN',
      'DATE AND TIME REPORTED': 'PETSA AT ORAS NG PAG-ULAT',
      'LOCATION': 'LOKASYON',
      'VIEW MESSAGE ALERT': 'TINGNAN ANG ALERTO NG MENSAHE',
      'MESSAGE': 'MENSAHE',
      'NEED IMMEDIATE ACTION!': 'KAILANGAN NG AGARANG AKSYON!',
      'No immediate action required': 'Walang kailangang agarang aksyon',
      'SEND ALERT': 'MAGPADALA NG ALERTO',
      'Alert sent and message stored successfully': 'Matagumpay na naipadala ang alerto at naitago ang mensahe',
      'Failed to send alert and store message': 'Hindi nagawa ang pagpapadala ng alerto at pag-iimbak ng mensahe',
      'New Alert Message': 'Bagong Mensahe ng Alerto',
      'A new alert has been created for': 'Isang bagong alerto ay ginawa para sa',
      'Immediate action may be required.': 'Maaaring kailanganin ng agarang aksyon.',
      'No immediate action is required.': 'Walang kailangang agarang aksyon.',
      'Location details not available': 'Hindi magamit ang mga detalye ng lokasyon',
      'Error fetching location details': 'Error sa pagkuha ng mga detalye ng lokasyon',
      'Location data not available': 'Hindi magamit ang datos ng lokasyon',
      'Fetching location...': 'Kinukuha ang lokasyon...',
      'No image available': 'Walang magagamit na larawan',
      'Failed to load image': 'Hindi na-load ang larawan',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto mo bang ireport ito sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'HINDI',
      'Report sent to BFAR successfully': 'Matagumpay na naipadala ang report sa BFAR',
      'Failed to send report to BFAR': 'Hindi nagawa ang pagpapadala ng report sa BFAR',
      'REPORT TO BFAR': 'ULAT SA BFAR',
      'SEND REPORT': 'MAGPADALA NG ULAT',
      'AT': 'SA',
    },
    'Bisaya': {
      'REPORT': 'REPORT',
      'ORGANISM': 'ORGANISMO',
      'FARM NAME': 'NGALAN SA UMAHAN',
      'OWNER': 'TAG-IYA',
      'CONTACT NUMBER': 'NUMERO SA KONTAK',
      'FEED TYPES': 'MGA MATANG SA PAGKAON',
      'DATE AND TIME REPORTED': 'PETSA UG ORAS SA PAG-REPORT',
      'LOCATION': 'LOKASYON',
      'VIEW MESSAGE ALERT': 'TAN-AWA ANG ALERTO SA MENSAHE',
      'MESSAGE': 'MENSAHE',
      'NEED IMMEDIATE ACTION!': 'KINAHANGLAN UG DIHA-DIHA NGA AKSYON!',
      'No immediate action required': 'Walay gikinahanglan nga diha-diha nga aksyon',
      'SEND ALERT': 'IPADALA ANG ALERTO',
      'Alert sent and message stored successfully': 'Malampusong napadala ang alerto ug natipigan ang mensahe',
      'Failed to send alert and store message': 'Napakyas sa pagpadala sa alerto ug pagtipig sa mensahe',
      'New Alert Message': 'Bag-ong Mensahe sa Alerto',
      'A new alert has been created for': 'Usa ka bag-ong alerto ang nahimo alang sa',
      'Immediate action may be required.': 'Mahimong gikinahanglan ang diha-diha nga aksyon.',
      'No immediate action is required.': 'Walay gikinahanglan nga diha-diha nga aksyon.',
      'Location details not available': 'Wala magamit ang mga detalye sa lokasyon',
      'Error fetching location details': 'Sayup sa pagkuha sa mga detalye sa lokasyon',
      'Location data not available': 'Wala magamit ang datos sa lokasyon',
      'Fetching location...': 'Gikuha ang lokasyon...',
      'No image available': 'Walay magamit nga hulagway',
      'Failed to load image': 'Napakyas sa pag-load sa hulagway',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto ba nimo ireport kini sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'DILI',
      'Report sent to BFAR successfully': 'Malampuson nga napadala ang report sa BFAR',
      'Failed to send report to BFAR': 'Napakyas sa pagpadala sa report sa BFAR',
      'REPORT TO BFAR': 'REPORT TO BFAR',
      'SEND REPORT': 'IPADALA ANG REPORT',
      'AT': 'SA',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchReportData();
    _getLocationDescription();
    _loadLanguagePreference();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _getLocationDescription() async {
    final data = widget.report?.data() as Map<String, dynamic>?;
    if (data != null && data['realtime_location'] != null && widget.report != null) {
      final lat = data['realtime_location'][0];
      final lng = data['realtime_location'][1];

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _locationDescription = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
          });
        } else {
          setState(() {
            _locationDescription = _getTranslatedText('Location details not available');
          });
        }
      } catch (e) {
        setState(() {
          _locationDescription = _getTranslatedText('Error fetching location details');
        });
      }
    } else {
      setState(() {
        _locationDescription = _getTranslatedText('Location data not available');
      });
    }
  }

  Future<void> _saveAlert(bool reportToBFAR) async {
    if (_isSendingAlert) return;

    setState(() {
      _isSendingAlert = true;
    });

    try {
      final data = widget.report?.data() as Map<String, dynamic>?;
      if (data == null || widget.report == null) {
        throw Exception('Report data is null');
      }

      final farmId = data['farmId'] as String?;
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final detection = data['detection'] ?? 'Unknown';
      final bool isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');

      // Create alert document
      DocumentReference alertRef = await _firestore.collection('alerts').add({
        'reportId': widget.report!.id,
        'farmName': data['farmName'] ?? 'Unknown',
        'ownerFirstName': data['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': data['ownerLastName'] ?? 'Unknown',
        'detection': detection,
        'latitude': data['realtime_location']?[0],
        'longitude': data['realtime_location']?[1],
        'locationDescription': _locationDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'status': isDiseaseDetected ? 'diseaselikelydetected' : 'diseasenotlikelydetected',
        'farmId': farmId,
        'requiresImmediateAction': isDiseaseDetected,
        'contactNumber': data['contactNumber'] ?? 'Unknown',
        'feedTypes': data['feedTypes'] ?? 'Unknown',
        'imageUrl': data['imageUrl'],
        'isNew': true,
        'isNewForAdmin': true,
        'isNewMessageFromAdmin': false,
        'reportedToBFAR': reportToBFAR,
      });

      // Create report document
      final reportRef = await _firestore.collection('reports').add({
        'detection': detection,
        'confidence': data['confidence'] ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'farmId': farmId,
        'farmName': data['farmName'] ?? 'Unknown',
        'ownerFirstName': data['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': data['ownerLastName'] ?? 'Unknown',
        'location': {
          'barangay': data['barangay'] ?? 'Unknown',
          'municipality': data['municipality'] ?? 'Unknown',
          'province': data['province'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
        },
        'realtime_location': data['realtime_location'] ?? GeoPoint(0, 0),
        'contactNumber': data['contactNumber'] ?? 'Unknown',
        'feedTypes': data['feedTypes'] ?? 'Unknown',
        'isNew': true,
        'isNewForAdmin': true,
        'reportedToBFAR': reportToBFAR,
        'imageUrl': data['imageUrl'],
      });

      // Update the alertRef to include the reportId
      await alertRef.update({
        'reportId': reportRef.id,
      });

      // Create message document
      await _firestore.collection('messages').add({
        'alertId': alertRef.id,
        'reportId': reportRef.id,
        'farmId': farmId,
        'content': 'Alert: $detection at ${data['farmName'] ?? 'Unknown Farm'}',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'type': 'alert',
        'isDiseaseDetected': isDiseaseDetected,
        'detection': detection,
        'farmName': data['farmName'] ?? 'Unknown',
        'ownerFirstName': data['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': data['ownerLastName'] ?? 'Unknown',
        'contactNumber': data['contactNumber'] ?? 'Unknown',
        'feedTypes': data['feedTypes'] ?? 'Unknown',
        'location': {
          'latitude': data['realtime_location']?[0],
          'longitude': data['realtime_location']?[1],
          'description': _locationDescription,
        },
        'imageUrl': data['imageUrl'],
        'source': 'fisher',
        'isNew': true,
        'isNewForAdmin': true,
        'isNewMessageFromAdmin': false,
        'reportedToBFAR': reportToBFAR,
      });

      // Show notification
      await _showNotification(
          _getTranslatedText('New Alert Message'),
          '${_getTranslatedText('A new alert has been created for')} $detection at ${data['farmName'] ?? 'Unknown Farm'}. ${isDiseaseDetected ? _getTranslatedText('Immediate action may be required.') : _getTranslatedText('No immediate action is required.')}'
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('Alert sent and message stored successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('Error saving alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('Failed to send alert and store message')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'alert_messages_channel',
      'Alert Messages Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      _getTranslatedText(title),
      _getTranslatedText(body),
      platformChannelSpecifics,
    );
  }

  String _extractOrganismName(String detection) {
    final parts = detection.split(' ');
    if (parts.length >= 2) {
      return parts[0];
    }
    return 'Unknown Organism';
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText(label),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp);
    } else {
      return 'Timestamp not available';
    }
  }

  Future<void> _showMessageAlert() async {
    if (_isSendingAlert) return;

    final data = widget.report?.data() as Map<String, dynamic>?;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Report data is not available')),
      );
      return;
    }

    final detection = data['detection'] ?? 'Unknown';
    final bool isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');
    final currentTimestamp = DateTime.now();

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslatedText('REPORT'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF40C4FF),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF40C4FF)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${detection.toUpperCase()} ${_getTranslatedText('AT')} ${data['farmName'] ?? 'UNKNOWN FARM'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('OWNER')}: ${data['ownerFirstName'] ?? ''} ${data['ownerLastName'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('LOCATION')}: $_locationDescription',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('DATE AND TIME REPORTED')}: ${_formatTimestamp(currentTimestamp)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDiseaseDetected ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isDiseaseDetected
                                    ? _getTranslatedText('NEED IMMEDIATE ACTION!')
                                    : _getTranslatedText('No immediate action required'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDiseaseDetected ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF40C4FF)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getTranslatedText('Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _reportToBFAR = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _reportToBFAR == true ? const Color(0xFF40C4FF) : Colors.grey[300],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    _getTranslatedText('YES'),
                                    style: TextStyle(
                                      color: _reportToBFAR == true ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _reportToBFAR = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _reportToBFAR == false ? Colors.red : Colors.grey[300],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    _getTranslatedText('NO'),
                                    style: TextStyle(
                                      color: _reportToBFAR == false ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _reportToBFAR == null
                              ? null
                              : () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            _getTranslatedText('SEND REPORT'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true && _reportToBFAR != null) {
      await _saveAlert(_reportToBFAR!);
      setState(() {
        _reportToBFAR = null;
      });
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

  void _fetchReportData() {
    final data = widget.report?.data() as Map<String, dynamic>?;
    if (data != null) {
      final timestamp = data['timestamp'] as Timestamp?;
      setState(() {
        _timestamp = timestamp != null ? _formatTimestamp(timestamp) : 'Timestamp not available';
      });
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.report?.data() as Map<String, dynamic>?;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Report Details'),
        ),
        body: Center(child: Text('Report data not available')),
      );
    }

    final detection = data['detection'] as String? ?? 'Unknown';
    final organismName = _extractOrganismName(detection);
    final bool isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');
    final imageUrl = data['imageUrl'] as String?;

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
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _getTranslatedText('REPORT'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF40C4FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: imageUrl != null
                          ? GestureDetector(
                        onTap: () => _showFullScreenImage(context, imageUrl),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF40C4FF),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text('Failed to load image'),
                            ),
                          ),
                        ),
                      )
                          : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(_getTranslatedText('No image available')),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF40C4FF)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF40C4FF)),
                            ),
                            child: Text(
                              organismName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF40C4FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTranslatedText('ORGANISM'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDiseaseDetected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDiseaseDetected ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDiseaseDetected ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', data['farmName'] ?? ''),
              _buildTextField('OWNER', '${data['ownerFirstName'] ?? ''} ${data['ownerLastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', data['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', data['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', _timestamp),
              _buildTextField('LOCATION', _locationDescription),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showMessageAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40C4FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _getTranslatedText('REPORT'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

