import 'package:flutter/material.dart';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../fisher_screens/fisher_container_screen/fisher_container_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportDetailsScreen extends StatefulWidget {
  final File imageFile;
  final String detection;
  final double confidence;
  final Map<String, dynamic> farmData;

  const ReportDetailsScreen({
    super.key,
    required this.imageFile,
    required this.detection,
    required this.confidence,
    required this.farmData,
  });

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  String _locationDescription = 'Fetching location...';
  bool _isSendingAlert = false;
  String _timestamp = 'Fetching timestamp...';
  String _imageUrl = '';
  bool _isUploadingImage = false;
  String? _imageUploadError;
  bool? _reportToBFAR;

  String _selectedLanguage = 'English';
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
      'SEND REPORT': 'MAGPADALA NG ULAT',
      'New Report Alert': 'Bagong Alerto ng Ulat',
      'A new report for': 'Isang bagong ulat para sa',
      'has been sent.': 'ay naipadala na.',
      'Immediate action may be required.': 'Maaaring kailanganin ng agarang aksyon.',
      'No immediate action is required.': 'Walang kailangang agarang aksyon.',
      'Failed to send alert and store message': 'Hindi nagawa ang pagpapadala ng alerto at pag-iimbak ng mensahe',
      'Fetching location...': 'Kinukuha ang lokasyon...',
      'Location details not available': 'Hindi magamit ang mga detalye ng lokasyon',
      'Error fetching location details': 'Error sa pagkuha ng mga detalye ng lokasyon',
      'Location data not available': 'Hindi magamit ang datos ng lokasyon',
      'Fetching timestamp...': 'Kinukuha ang timestamp...',
      'Failed to upload image': 'Hindi na-upload ang larawan',
      'Retry Upload': 'Subukang Mag-upload Muli',
      'No Image Available': 'Walang Magagamit na Larawan',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto mo bang ireport ito sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'HINDI',
      'REPORT': 'ULAT'
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
      'SEND REPORT': 'IPADALA ANG REPORT',
      'New Report Alert': 'Bag-ong Alerto sa Report',
      'A new report for': 'Usa ka bag-ong report alang sa',
      'has been sent.': 'gipadala na.',
      'Immediate action may be required.': 'Mahimong gikinahanglan ang diha-diha nga aksyon.',
      'No immediate action is required.': 'Walay gikinahanglan nga diha-diha nga aksyon.',
      'Failed to send alert and store message': 'Napakyas sa pagpadala sa alerto ug pagtipig sa mensahe',
      'Fetching location...': 'Gikuha ang lokasyon...',
      'Location details not available': 'Wala magamit ang mga detalye sa lokasyon',
      'Error fetching location details': 'Sayup sa pagkuha sa mga detalye sa lokasyon',
      'Location data not available': 'Wala magamit ang datos sa lokasyon',
      'Fetching timestamp...': 'Gikuha ang timestamp...',
      'Failed to upload image': 'Napakyas sa pag-upload sa hulagway',
      'Retry Upload': 'Sulayi Pag-usab ang Pag-upload',
      'No Image Available': 'Walay Magamit nga Hulagway',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto ba nimo ireport kini sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'DILI',
      'REPORT': 'ULAT'
    },
  };

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getLocationDescription();
    _uploadImage();
    _loadLanguagePreference();
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

  Future<void> _getLocationDescription() async {
    if (widget.farmData['realtime_location'] != null) {
      final lat = widget.farmData['realtime_location'][0];
      final lng = widget.farmData['realtime_location'][1];

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

  Future<void> _uploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('report_images')
          .child('${widget.farmData['farmId']}.jpg'); // Updated image path
      await ref.putFile(widget.imageFile);
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url;
        _isUploadingImage = false;
      });
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isUploadingImage = false;
        _imageUploadError = _getTranslatedText('Failed to upload image');
      });
    }
  }

  Future<void> _createReport() async {
    if (_isSendingAlert || _isUploadingImage) return;

    setState(() {
      _isSendingAlert = true;
    });

    try {
      final farmId = widget.farmData['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final bool isVirusLikelyDetected = !widget.detection.toLowerCase().contains('not likely detected');

      // Ensure the image is uploaded before saving the report
      if (_imageUrl.isEmpty) {
        await _uploadImage();
      }

      // Create report document
      final reportRef = await FirebaseFirestore.instance.collection('reports').add({
        'detection': widget.detection,
        'confidence': widget.confidence,
        'timestamp': FieldValue.serverTimestamp(),
        'farmId': farmId,
        'farmName': widget.farmData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.farmData['firstName'] ?? 'Unknown',
        'ownerLastName': widget.farmData['lastName'] ?? 'Unknown',
        'location': {
          'barangay': widget.farmData['barangay'] ?? 'Unknown',
          'municipality': widget.farmData['municipality'] ?? 'Unknown',
          'province': widget.farmData['province'] ?? 'Unknown',
          'region': widget.farmData['region'] ?? 'Unknown',
        },
        'realtime_location': widget.farmData['realtime_location'] ?? GeoPoint(0, 0),
        'contactNumber': widget.farmData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.farmData['feedTypes'] ?? 'Unknown',
        'isNew': true,
        'isNewForAdmin': true,
        'reportedToBFAR': _reportToBFAR,
        'imageUrl': _imageUrl,
      });

      // Create alert document
      final alertRef = await FirebaseFirestore.instance.collection('alerts').add({
        'reportId': reportRef.id,
        'farmName': widget.farmData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.farmData['firstName'] ?? 'Unknown',
        'ownerLastName': widget.farmData['lastName'] ?? 'Unknown',
        'detection': widget.detection,
        'latitude': widget.farmData['realtime_location']?[0],
        'longitude': widget.farmData['realtime_location']?[1],
        'locationDescription': _locationDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'status': isVirusLikelyDetected ? 'viruslikelydetected' : 'virusnotlikelydetected',
        'farmId': farmId,
        'requiresImmediateAction': isVirusLikelyDetected,
        'contactNumber': widget.farmData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.farmData['feedTypes'] ?? 'Unknown',
        'imageUrl': _imageUrl,
        'isNew': true,
        'isNewForAdmin': true,
        'isNewMessageFromAdmin': false,
        'reportedToBFAR': _reportToBFAR,
      });

      // Create message document
      await FirebaseFirestore.instance.collection('messages').add({
        'alertId': alertRef.id,
        'reportId': reportRef.id,
        'farmId': farmId,
        'content': 'Alert: ${widget.detection} at ${widget.farmData['farmName'] ?? 'Unknown Farm'}',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'type': 'alert',
        'isVirusLikelyDetected': isVirusLikelyDetected,
        'detection': widget.detection,
        'farmName': widget.farmData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.farmData['firstName'] ?? 'Unknown',
        'ownerLastName': widget.farmData['lastName'] ?? 'Unknown',
        'contactNumber': widget.farmData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.farmData['feedTypes'] ?? 'Unknown',
        'location': {
          'latitude': widget.farmData['realtime_location']?[0],
          'longitude': widget.farmData['realtime_location']?[1],
          'description': _locationDescription,
        },
        'imageUrl': _imageUrl,
        'source': 'fisher',
        'isNew': true,
        'isNewForAdmin': true,
        'isNewMessageFromAdmin': false,
        'reportedToBFAR': _reportToBFAR,
      });

      // Show notification
      await _showNotification(
          _getTranslatedText('New Report Alert'),
          '${_getTranslatedText('A new report for')} ${widget.detection} ${_getTranslatedText('at')} ${widget.farmData['farmName'] ?? 'Unknown Farm'} ${_getTranslatedText('has been sent.')} ${isVirusLikelyDetected ? _getTranslatedText('Immediate action may be required.') : _getTranslatedText('No immediate action is required.')}'
      );

      // Navigate to FisherContainerScreen and remove all previous routes
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => FisherContainerScreen(farmId: farmId)),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getTranslatedText('Failed to create report')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
      }
    }
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


  Future<void> _showMessageAlert() async {
    final bool isVirusLikelyDetected = !widget.detection.toLowerCase().contains('not likely detected');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
                              '${widget.detection.toUpperCase()} ${_getTranslatedText('AT')} ${widget.farmData['farmName'] ?? 'UNKNOWN FARM'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('OWNER')}: ${widget.farmData['firstName'] ?? ''} ${widget.farmData['lastName'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('LOCATION')}: $_locationDescription',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTranslatedText('DATE AND TIME REPORTED')}: ${_formatTimestamp(DateTime.now())}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isVirusLikelyDetected ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isVirusLikelyDetected
                                    ? _getTranslatedText('NEED IMMEDIATE ACTION!')
                                    : _getTranslatedText('No immediate action required'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isVirusLikelyDetected ? Colors.red : Colors.green,
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            Navigator.of(context).pop();
                            _createReport();
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
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
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
      _getTranslatedText(title),
      _getTranslatedText(body),
      platformChannelSpecifics,
    );
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
    final organismName = _extractOrganismName(widget.detection);
    final bool isVirusLikelyDetected = !widget.detection.toLowerCase().contains('not likely detected');

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
                      child: _isUploadingImage
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : _imageUploadError != null
                          ? Center(
                        child: Text(
                          _imageUploadError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                          : _imageUrl.isNotEmpty
                          ? GestureDetector(
                        onTap: () => _showFullScreenImage(context, _imageUrl),
                        child: CachedNetworkImage(
                          imageUrl: _imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      )
                          : GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.imageFile.path),
                        child: Image.file(
                          widget.imageFile,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
              if (_imageUploadError != null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _imageUploadError = null;
                    });
                    _uploadImage();
                  },
                  child: Text(_getTranslatedText('Retry Upload')),
                ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isVirusLikelyDetected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    widget.detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', widget.farmData['farmName'] ?? ''),
              _buildTextField('OWNER', '${widget.farmData['firstName'] ?? ''} ${widget.farmData['lastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', widget.farmData['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', widget.farmData['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', _formatTimestamp(DateTime.now())),
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

