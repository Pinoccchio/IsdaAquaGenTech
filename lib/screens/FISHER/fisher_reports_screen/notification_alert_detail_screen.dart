import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationAlertDetailScreen extends StatelessWidget {
  final Map<String, dynamic> alert;

  const NotificationAlertDetailScreen({Key? key, required this.alert}) : super(key: key);

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
    final timestamp = alert['timestamp'] as Timestamp;
    final formattedTimestamp = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
    final requiresImmediateAction = alert['requiresImmediateAction'] as bool;
    final detection = alert['detection'] as String;
    final imageUrl = alert['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF40C4FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alert Details',
          style: TextStyle(color: Color(0xFF40C4FF), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'ALERT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF40C4FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF40C4FF)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF40C4FF)),
                  ),
                  child: Center(
                    child: Text(
                      'No Image Available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: requiresImmediateAction
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: requiresImmediateAction ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: requiresImmediateAction ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', alert['farmName'] ?? ''),
              _buildTextField('OWNER', '${alert['ownerFirstName'] ?? ''} ${alert['ownerLastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', alert['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', alert['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', formattedTimestamp),
              _buildTextField('LOCATION', alert['locationDescription'] ?? ''),
              _buildTextField('LATITUDE', alert['latitude']?.toString() ?? ''),
              _buildTextField('LONGITUDE', alert['longitude']?.toString() ?? ''),
              _buildTextField('FARM ID', alert['farmId'] ?? ''),
              _buildTextField('REPORT ID', alert['reportId'] ?? ''),
              _buildTextField('STATUS', alert['status'] ?? ''),
              _buildTextField('REQUIRES IMMEDIATE ACTION', requiresImmediateAction ? 'Yes' : 'No'),
            ],
          ),
        ),
      ),
    );
  }
}

