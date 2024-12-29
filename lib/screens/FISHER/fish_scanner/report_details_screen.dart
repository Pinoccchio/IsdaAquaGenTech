import 'package:flutter/material.dart';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;
  final File imageFile;
  final String detection;
  final Map<String, dynamic> farmData;

  const ReportDetailsScreen({
    Key? key,
    required this.reportId,
    required this.imageFile,
    required this.detection,
    required this.farmData,
  }) : super(key: key);

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  String _locationDescription = 'Fetching location...';
  bool _isSendingAlert = false;
  String _timestamp = 'Fetching timestamp...'; // Added timestamp state variable

  @override
  void initState() {
    super.initState();
    _getLocationDescription();
    _fetchReportData(); // Call the new method here
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
      final farmId = widget.farmData['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      // Save the alert directly in the farm document
      await FirebaseFirestore.instance
          .collection('alerts')
          .add({
        'reportId': widget.reportId,
        'farmName': widget.farmData['farmName'],
        'ownerFirstName': widget.farmData['firstName'],
        'ownerLastName': widget.farmData['lastName'],
        'detection': widget.detection,
        'latitude': widget.farmData['realtime_location'][0],
        'longitude': widget.farmData['realtime_location'][1],
        'locationDescription': _locationDescription,
        'timestamp': _timestamp,
        'status': widget.detection.toLowerCase().contains('not likely detected')
            ? 'virusnotlikelydetected'
            : 'viruslikelydetected',
        'farmId': farmId,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close the dialog
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
                        '${widget.detection.toUpperCase()} AT ${widget.farmData['farmName'] ?? 'UNKNOWN FARM'} (OWNER: ${widget.farmData['firstName'] ?? ''} ${widget.farmData['lastName'] ?? ''})',
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
                      const Text(
                        'NEED IMMEDIATE ACTION!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
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
          .doc(widget.reportId)
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
    final organismName = _extractOrganismName(widget.detection);

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
                  'REPORT #${widget.reportId}',
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
                      child: Image.file(
                        widget.imageFile,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
                    color: widget.detection.toLowerCase().contains('not likely detected')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.detection.toLowerCase().contains('not likely detected')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    widget.detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.detection.toLowerCase().contains('not likely detected')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', widget.farmData['farmName'] ?? ''),
              _buildTextField('OWNER', '${widget.farmData['firstName'] ?? ''} ${widget.farmData['lastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', widget.farmData['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', widget.farmData['feedTypes'] ?? ''),
              _buildTextField('LOCATION', '${widget.farmData['barangay'] ?? ''}, ${widget.farmData['municipality'] ?? ''}, ${widget.farmData['province'] ?? ''}, ${widget.farmData['region'] ?? ''}'),
              _buildTextField('DATE AND TIME REPORTED', _timestamp), // Updated timestamp field
              _buildTextField('REAL-TIME LOCATION', _locationDescription),
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

