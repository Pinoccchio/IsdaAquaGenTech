import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatefulWidget {
  final DocumentSnapshot report;

  const ReportDetailScreen({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String _locationDescription = 'Fetching location...';
  bool _isSendingAlert = false;
  String _timestamp = 'Fetching timestamp...';

  @override
  void initState() {
    super.initState();
    _getLocationDescription();
    _fetchReportData();
  }

  Future<void> _getLocationDescription() async {
    final data = widget.report.data() as Map<String, dynamic>;
    if (data['realtime_location'] != null) {
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
            _locationDescription = 'Location details not available';
          });
        }
      } catch (e) {
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

  Future<void> _saveAlert() async {
    if (_isSendingAlert) return;

    setState(() {
      _isSendingAlert = true;
    });

    try {
      final data = widget.report.data() as Map<String, dynamic>;
      final farmId = data['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final detection = data['detection'] ?? 'Unknown';
      final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');

      await FirebaseFirestore.instance
          .collection('alerts')
          .add({
        'reportId': widget.report.id,
        'farmName': data['farmName'],
        'ownerFirstName': data['ownerFirstName'],
        'ownerLastName': data['ownerLastName'],
        'detection': detection,
        'latitude': data['realtime_location']?[0],
        'longitude': data['realtime_location']?[1],
        'locationDescription': _locationDescription,
        'timestamp': _timestamp,
        'status': isVirusLikelyDetected ? 'viruslikelydetected' : 'virusnotlikelydetected',
        'farmId': farmId,
        'requiresImmediateAction': isVirusLikelyDetected,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send alert'),
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
    final data = widget.report.data() as Map<String, dynamic>;
    final detection = data['detection'] ?? 'Unknown';
    final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MESSAGE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detection.toUpperCase()} AT ${data['farmName'] ?? 'UNKNOWN FARM'} (OWNER: ${data['ownerFirstName'] ?? ''} ${data['ownerLastName'] ?? ''})',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LOCATION: $_locationDescription',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TIMESTAMP: $_timestamp',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isVirusLikelyDetected)
                        const Text(
                          'NEED IMMEDIATE ACTION!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        )
                      else
                        const Text(
                          'No immediate action required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSendingAlert ? null : _saveAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSendingAlert
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'SEND ALERT',
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

  Future<void> _fetchReportData() async {
    try {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.report.id)
          .get();

      if (reportDoc.exists) {
        Map<String, dynamic> data = reportDoc.data() as Map<String, dynamic>;
        setState(() {
          _timestamp = _formatTimestamp(data['timestamp']);
        });
      }
    } catch (e) {
      print('Error fetching report data: $e');
      setState(() {
        _timestamp = 'Timestamp not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.report.data() as Map<String, dynamic>;
    final detection = data['detection'] ?? 'Unknown';
    final organismName = _extractOrganismName(detection);
    final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');
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
                  'REPORT #${widget.report.id}',
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
                          ? Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFF40C4FF),
                              ),
                            ),
                          );
                        },
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
                    detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
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
                  child: const Text(
                    'VIEW MESSAGE ALERT',
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

