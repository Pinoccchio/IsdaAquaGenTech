import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final String reportId;

  const AdminReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  _AdminReportDetailScreenState createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  String _locationDescription = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final reportDoc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    if (reportDoc.exists) {
      final data = reportDoc.data() as Map<String, dynamic>;
      _getLocationDescription(data);
    }
  }

  Future<void> _getLocationDescription(Map<String, dynamic> reportData) async {
    setState(() {
      _locationDescription = 'Fetching location...';
    });

    if (reportData['realtime_location'] != null) {
      final lat = reportData['realtime_location'][0];
      final lng = reportData['realtime_location'][1];

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

  Future<void> _showMessageAlert(BuildContext context, Map<String, dynamic> reportData) async {
    final TextEditingController messageController = TextEditingController();
    final detection = reportData['detection'] as String? ?? 'Unknown';
    final bool isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                      Navigator.of(dialogContext).pop();
                      _sendMessage(context, isDiseaseDetected, messageController.text, reportData);
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

  Future<void> _sendMessage(BuildContext context, bool isDiseaseDetected, String message, Map<String, dynamic> reportData) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({'isNewForAdmin': false});
      final farmId = reportData['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final detection = reportData['detection'] as String? ?? 'Unknown';

      // Store the message
      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'reportId': widget.reportId,
        'farmId': farmId,
        'content': 'Report: $detection at ${reportData['farmName'] ?? 'Unknown Farm'}',
        'replyMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'type': 'report',
        'isDiseaseDetected': isDiseaseDetected,
        'detection': detection,
        'farmName': reportData['farmName'] ?? 'Unknown',
        'ownerFirstName': reportData['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': reportData['ownerLastName'] ?? 'Unknown',
        'contactNumber': reportData['contactNumber'] ?? 'Unknown',
        'feedTypes': reportData['feedTypes'] ?? 'Unknown',
        'location': {
          'latitude': reportData['realtime_location']?[0],
          'longitude': reportData['realtime_location']?[1],
          'description': _locationDescription,
        },
        'imageUrl': reportData['imageUrl'] ?? '',
        'source': 'admin',
        'isNew': true,
        'isNewForAdmin': false,
        'isNewMessageFromAdmin': true,
      });

      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close the dialog

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String detection) {
    return detection.toLowerCase().contains('not likely detected') ? Colors.green : Colors.red;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, y h:mm a').format(timestamp.toDate());
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'Invalid timestamp';
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
          height: 40,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Report not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final detection = data['detection'] ?? 'Unknown';
          final organismName = _extractOrganismName(detection);
          final imageUrl = data['imageUrl'] as String?;
          final timestamp = data['timestamp'] as Timestamp;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'REPORT DETAILS',
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
                        color: _getStatusColor(detection).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(detection),
                        ),
                      ),
                      child: Text(
                        detection.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(detection),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('FARM NAME', data['farmName'] ?? ''),
                  _buildTextField('OWNER', '${data['ownerFirstName'] ?? ''} ${data['ownerLastName'] ?? ''}'),
                  _buildTextField('CONTACT NUMBER', data['contactNumber'] ?? ''),
                  _buildTextField('FEED TYPES', data['feedTypes'] ?? ''),
                  _buildTextField('DATE AND TIME REPORTED', _formatTimestamp(timestamp)),
                  _buildTextField('LOCATION', _locationDescription),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showMessageAlert(context, data),
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
          );
        },
      ),
    );
  }
}

