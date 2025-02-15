import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'fisher_message_detail_screen.dart';

class FisherMessageScreen extends StatelessWidget {
  final String farmId;

  const FisherMessageScreen({
    super.key,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
            .where('farmId', isEqualTo: farmId)
            .orderBy('timestamp', descending: false)
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
              return _buildMessageBubble(context, message);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isAdmin = data['source'] == 'admin';
    final timestamp = data['timestamp'] as Timestamp;
    final dateTime = timestamp.toDate();
    final formattedTime = DateFormat('h:mm a').format(dateTime);
    final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
    final reportedToBFAR = data['reportedToBFAR'] as bool? ?? false;

    final detection = data['detection'] as String? ?? '';
    final isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');

    Color bubbleColor;
    if (isAdmin) {
      bubbleColor = isDiseaseDetected ? Colors.red[100]! : Colors.green[100]!;
    } else {
      bubbleColor = isDiseaseDetected ? Colors.red[100]! : Colors.green[100]!;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(
              messageId: message.id,
              farmId: farmId,
            ),
          ),
        );
        // Update the message isNew field to false after viewing
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(message.id)
            .update({'isNew': false});
      },
      child: Align(
        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detection.isNotEmpty)
                Text(
                  detection.toUpperCase(),
                  style: TextStyle(
                    color: isDiseaseDetected ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              if (detection.isNotEmpty)
                const SizedBox(height: 4),
              Text(
                _getMessagePreview(data),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$formattedDate at $formattedTime',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reported to BFAR: ${reportedToBFAR ? 'Yes' : 'No'}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              if (data['isNew'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 150,
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(Map<String, dynamic> data) {
    if (data['requestedChanges'] != null) {
      return 'Edit request submitted from ${data['requestedChanges']['farmName'] ?? 'farm'}';
    } else if (data['source'] == 'admin') {
      return data['replyMessage'] as String? ?? 'No message content';
    } else {
      final content = data['content'] as String? ?? 'No message content';
      return content.startsWith('Alert:') ? content.replaceFirst('Alert:', 'Report:') : content;
    }
  }
}

