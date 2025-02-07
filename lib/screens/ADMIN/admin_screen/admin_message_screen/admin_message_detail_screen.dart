import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminMessageDetailScreen extends StatelessWidget {
  final String messageId;
  final String farmId;

  const AdminMessageDetailScreen({
    super.key,
    required this.messageId,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF40C4FF);
    const Color adminColor = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('messages').doc(messageId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Message not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            if (data['farmId'] != farmId) {
              return const Center(child: Text('Message not found for this farm'));
            }

            final timestamp = data['timestamp'] as Timestamp;
            final dateTime = timestamp.toDate();
            final formattedDate = DateFormat('MMMM d, yyyy').format(dateTime);
            final formattedTime = DateFormat('h:mm a').format(dateTime);
            final isVirusLikelyDetected = data['isVirusLikelyDetected'] ?? false;
            final isAdminMessage = data['source'] == 'admin';

            // Mark the message as read for admin
            FirebaseFirestore.instance.collection('messages').doc(messageId).update({'isNewForAdmin': false});

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isAdminMessage ? adminColor : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isAdminMessage ? adminColor.withOpacity(0.3) : primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID #${messageId.toString().padLeft(6, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAdminMessage ? adminColor.withOpacity(0.1) : (isVirusLikelyDetected ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAdminMessage ? 'From Admin' : 'From Fisher',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isAdminMessage ? adminColor : (isVirusLikelyDetected ? Colors.red : Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Detection:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['detection'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            color: isVirusLikelyDetected ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Farm Details:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: ${data['farmName'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Owner: ${data['ownerFirstName'] ?? 'Unknown'} ${data['ownerLastName'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Contact: ${data['contactNumber'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Feed Types: ${data['feedTypes'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Location:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatLocation(data['location']),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fish Image:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImageWidget(data['imageUrl']),
                        const SizedBox(height: 24),
                        Text(
                          'Message:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isAdminMessage ? adminColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdminMessage ? (data['replyMessage'] ?? 'No message content') : (data['content'] ?? 'No message content'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        if (data['visitationDateTime'] != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Visitation Date and Time:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isAdminMessage ? adminColor : primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['visitationDateTime'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatLocation(dynamic location) {
    if (location is String) {
      return location;
    } else if (location is Map<String, dynamic>) {
      return location['description'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        ),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

