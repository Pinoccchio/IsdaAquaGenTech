import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminHomescreenFisherDetailedScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const AdminHomescreenFisherDetailedScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  _AdminHomescreenFisherDetailedScreenState createState() => _AdminHomescreenFisherDetailedScreenState();
}

class _AdminHomescreenFisherDetailedScreenState extends State<AdminHomescreenFisherDetailedScreen> {
  bool _isSendingAlert = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String _locationDescription = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    //_updateReportStatus(); //Commented out as per the update request.
    _getLocationDescription();
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
      'fish_farm_channel_id',
      'Fish Farm Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Future<void> _updateReportStatus() async { //Commented out as per the update request.
  //   await FirebaseFirestore.instance
  //       .collection('reports')
  //       .doc(widget.reportId)
  //       .update({'isNewForAdmin': false});
  // }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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

  String _extractOrganismName(String detection) {
    final parts = detection.split(' ');
    if (parts.length >= 2) {
      return parts[0];
    }
    return 'Unknown Organism';
  }

  Future<void> _showMessageAlert() async {
    final TextEditingController messageController = TextEditingController();
    final detection = widget.reportData['detection'] as String? ?? 'Unknown';
    final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPLY',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter your message here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF40C4FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF40C4FF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendAlert(isVirusLikelyDetected, messageController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40C4FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'REPLY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAlert(bool isVirusLikelyDetected, String message) async {
    if (_isSendingAlert) return;

    setState(() {
      _isSendingAlert = true;
    });

    try {
      final farmId = widget.reportData['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final detection = widget.reportData['detection'] as String? ?? 'Unknown';

      // Save the alert in the alerts collection
      final alertRef = await FirebaseFirestore.instance
          .collection('alerts')
          .add({
        'reportId': widget.reportId,
        'farmName': widget.reportData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.reportData['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': widget.reportData['ownerLastName'] ?? 'Unknown',
        'detection': detection,
        'latitude': widget.reportData['realtime_location']?[0],
        'longitude': widget.reportData['realtime_location']?[1],
        'locationDescription': _locationDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'status': isVirusLikelyDetected ? 'viruslikelydetected' : 'virusnotlikelydetected',
        'farmId': farmId,
        'requiresImmediateAction': isVirusLikelyDetected,
        'contactNumber': widget.reportData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.reportData['feedTypes'] ?? 'Unknown',
        'imageUrl': widget.reportData['imageUrl'] ?? '',
        'isNew': true,
        'isNewForAdmin': true,
      });

      // Store the alert as a message
      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'alertId': alertRef.id,
        'farmId': farmId,
        'content': 'Alert: $detection at ${widget.reportData['farmName'] ?? 'Unknown Farm'}',
        'replyMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'type': 'alert',
        'isVirusLikelyDetected': isVirusLikelyDetected,
        'detection': detection,
        'farmName': widget.reportData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.reportData['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': widget.reportData['ownerLastName'] ?? 'Unknown',
        'contactNumber': widget.reportData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.reportData['feedTypes'] ?? 'Unknown',
        'location': {
          'latitude': widget.reportData['realtime_location']?[0],
          'longitude': widget.reportData['realtime_location']?[1],
          'description': _locationDescription,
        },
        'imageUrl': widget.reportData['imageUrl'] ?? '',
        'source': 'admin',
        'isNew': true,
        'isNewForAdmin': false,
        'isNewMessageFromAdmin': true,
      });

      // Update the report status
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({'isNewForAdmin': false});

      await _showNotification(
          'New Report Alert',
          'A new report for $detection at ${widget.reportData['farmName'] ?? 'Unknown Farm'} has been sent. ${isVirusLikelyDetected ? 'Immediate action may be required.' : 'No immediate action is required.'}'
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent and message stored successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert and store message: $e'),
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

  Future<void> _getLocationDescription() async {
    setState(() {
      _locationDescription = 'Fetching location...';
    });

    if (widget.reportData['realtime_location'] != null) {
      final lat = widget.reportData['realtime_location'][0];
      final lng = widget.reportData['realtime_location'][1];

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _locationDescription = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
          });
        } else {
          setState(() {
            _locationDescription = 'Location details not available';
          });
        }
      } catch (e) {
        print('Error fetching location details: $e');
        setState(() {
          _locationDescription = 'Error fetching location details';
        });
      }
    } else {
      setState(() {
        _locationDescription = 'Location data not available';
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
    final organismName = _extractOrganismName(widget.reportData['detection']);
    final bool isVirusLikelyDetected = !widget.reportData['detection'].toLowerCase().contains('not likely detected');

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
              const Center(
                child: Text(
                  'REPORT',
                  style: TextStyle(
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
                      child: widget.reportData['imageUrl'] != null && widget.reportData['imageUrl'].isNotEmpty
                          ? GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.reportData['imageUrl']),
                        child: CachedNetworkImage(
                          imageUrl: widget.reportData['imageUrl'],
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
                              child: Icon(Icons.error),
                            ),
                          ),
                        ),
                      )
                          : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('No image available'),
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
                          const Text(
                            'ORGANISM',
                            style: TextStyle(
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
                    color: isVirusLikelyDetected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    widget.reportData['detection'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', widget.reportData['farmName'] ?? ''),
              _buildTextField('OWNER', '${widget.reportData['ownerFirstName'] ?? ''} ${widget.reportData['ownerLastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', widget.reportData['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', widget.reportData['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', _formatTimestamp(widget.reportData['timestamp'])),
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
                  child: const Text(
                    'REPLY',
                    style: TextStyle(
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

