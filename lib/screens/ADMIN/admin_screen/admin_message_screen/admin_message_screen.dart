import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_message_detail_screen.dart';

class AdminMessageScreen extends StatelessWidget {
  const AdminMessageScreen({Key? key}) : super(key: key);

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var message = snapshot.data!.docs[index];
              return _buildMessageCard(context, message);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp;
    final dateTime = timestamp.toDate();
    final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);
    final isVirusLikelyDetected = data['isVirusLikelyDetected'] ?? false;
    final isAdminMessage = data['source'] == 'admin';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminMessageDetailScreen(
              messageId: message.id,
              farmId: data['farmId'],
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['farmName'] ?? 'Unknown Farm',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF40C4FF),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdminMessage
                          ? Colors.purple.withOpacity(0.1)
                          : (isVirusLikelyDetected ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAdminMessage ? 'Admin' : (isVirusLikelyDetected ? 'Alert' : 'Normal'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAdminMessage
                            ? Colors.purple
                            : (isVirusLikelyDetected ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['content'] ?? 'No content',
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$formattedDate at $formattedTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

