import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportDetailScreen extends StatelessWidget {
  final String alertId;

  const AdminReportDetailScreen({
    Key? key,
    required this.alertId,
  }) : super(key: key);

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALERT DETAILS',
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
                        alert['detection'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(alert['detection']),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Farm: ${alert['farmName']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Owner: ${alert['ownerFirstName']} ${alert['ownerLastName']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location: ${alert['locationDescription']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      Text(
                        'Timestamp: ${_formatTimestamp(alert['timestamp'])}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (alert['requiresImmediateAction'] == true)
                        const Text(
                          'NEED IMMEDIATE ACTION!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        )
                      else
                        const Text(
                          'CONTINUE MONITORING YOUR FARM AND REPORT ANY CHANGES IN FISH HEALTH.',
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF40C4FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CLOSE',
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

  Color _getStatusColor(String detection) {
    if (detection.toUpperCase().contains('NOT LIKELY')) {
      return Colors.green;
    } else if (detection.toUpperCase().contains('LIKELY DETECTED')) {
      return Colors.red;
    }
    return Colors.grey;
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
        future: FirebaseFirestore.instance.collection('alerts').doc(alertId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Alert not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final detection = data['detection'] ?? 'Unknown';
          final organismName = _extractOrganismName(detection);
          final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');
          final imageUrl = data['imageUrl'] as String?;
          final timestamp = data['timestamp'] as Timestamp;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'REPORT DETAILS',
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
                  _buildTextField('DATE AND TIME REPORTED', _formatTimestamp(timestamp)),
                  _buildTextField('LOCATION', data['locationDescription'] ?? ''),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showAlertDetails(context, data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40C4FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'VIEW ALERT',
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


