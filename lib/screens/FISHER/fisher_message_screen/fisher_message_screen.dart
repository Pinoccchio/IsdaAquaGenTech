import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'fisher_message_detail_screen.dart';

class FisherMessageScreen extends StatefulWidget {
  final String farmId;

  const FisherMessageScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FisherMessageScreen> createState() => _FisherMessageScreenState();
}

class _FisherMessageScreenState extends State<FisherMessageScreen> {
  final Color primaryColor = const Color(0xFF40C4FF);
  final Color adminColor = Colors.purple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .where('farmId', isEqualTo: widget.farmId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 64,
                            color: primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final data = message.data() as Map<String, dynamic>;
                      final messageId = message.id;
                      final hasUnread = data['status'] == 'unread';
                      final timestamp = data['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      final formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
                      final isVirusLikelyDetected = data['isVirusLikelyDetected'] ?? false;
                      final isAdminMessage = data['source'] == 'admin';

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageDetailScreen(
                                messageId: messageId,
                                farmId: widget.farmId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasUnread
                                ? (isAdminMessage ? adminColor.withOpacity(0.1) : primaryColor.withOpacity(0.1))
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isAdminMessage ? adminColor.withOpacity(0.3) : primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isAdminMessage)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6, right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isVirusLikelyDetected ? Colors.red : Colors.green,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isAdminMessage ? 'From Admin' : 'To Admin',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isAdminMessage ? adminColor : primaryColor,
                                          ),
                                        ),
                                        if (hasUnread)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isAdminMessage ? adminColor : primaryColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'New',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getMessagePreview(data),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isAdminMessage ? Colors.grey[800] : (isVirusLikelyDetected ? Colors.red : Colors.green),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isAdminMessage ? adminColor : primaryColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview(Map<String, dynamic> data) {
    if (data['source'] == 'admin') {
      return 'From Admin: ${data['replyMessage'] ?? 'No message content'}';
    } else {
      final detection = data['detection'] ?? 'Unknown';
      final isVirusLikelyDetected = data['isVirusLikelyDetected'] ?? false;
      if (isVirusLikelyDetected) {
        return 'To Admin: Alert - $detection detected';
      } else {
        return 'To Admin: Report - $detection';
      }
    }
  }
}


