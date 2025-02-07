import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'admin_message_detail_screen.dart';

class FarmMessageScreen extends StatelessWidget {
  final String farmId;
  final String farmName;

  const FarmMessageScreen({super.key, required this.farmId, required this.farmName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(farmName),
        backgroundColor: const Color(0xFF40C4FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('farmId', isEqualTo: farmId)
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

          // Mark non-admin messages as read
          for (var doc in snapshot.data!.docs) {
            if (doc['isNewForAdmin'] == true && doc['source'] != 'admin') {
              FirebaseFirestore.instance
                  .collection('messages')
                  .doc(doc.id)
                  .update({'isNewForAdmin': false});
            }
          }

          return ListView.builder(
            reverse: true,
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
    final formattedTime = DateFormat('MMM d, y • h:mm a').format(dateTime);

    final isNewAdminReply = isAdmin && (data['isNewForAdmin'] ?? false);
    final isNewMessageFromAdmin = isAdmin && (data['isNewMessageFromAdmin'] ?? false);

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
        if (isNewAdminReply) {
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(message.id)
              .update({'isNewForAdmin': false});
        }
        if (isNewMessageFromAdmin) {
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(message.id)
              .update({'isNewMessageFromAdmin': false});
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminMessageDetailScreen(
              messageId: message.id,
              farmId: farmId,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Align(
            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
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
                    isAdmin ? data['replyMessage'] ?? '' : data['content'] ?? '',
                    style: TextStyle(
                      color: isAdmin ? Colors.black : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, data['imageUrl']),
                      child: Container(
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
                    ),
                ],
              ),
            ),
          ),
          if (isNewMessageFromAdmin)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
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
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
}

