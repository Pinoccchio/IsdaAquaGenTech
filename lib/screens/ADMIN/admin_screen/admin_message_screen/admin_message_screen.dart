import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'farm_message_screen.dart';
import 'package:intl/intl.dart';

class AdminMessageScreen extends StatelessWidget {
  const AdminMessageScreen({super.key});

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
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

          // Group messages by farmId
          Map<String, DocumentSnapshot> latestMessages = {};
          for (var doc in snapshot.data!.docs) {
            String farmId = doc['farmId'];
            if (!latestMessages.containsKey(farmId)) {
              latestMessages[farmId] = doc;
            }
          }

          return ListView.builder(
            itemCount: latestMessages.length,
            itemBuilder: (context, index) {
              var farmId = latestMessages.keys.elementAt(index);
              var latestMessage = latestMessages[farmId]!;
              return _buildFarmListItem(context, farmId, latestMessage);
            },
          );
        },
      ),
    );
  }

  Widget _buildFarmListItem(BuildContext context, String farmId, DocumentSnapshot latestMessage) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('farms').doc(farmId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text('Loading...'));
        }

        var farmData = snapshot.data!.data() as Map<String, dynamic>?;
        final farmName = farmData?['farmName'] ?? 'Unknown Farm';
        final pondImageUrl = farmData?['pondImageUrl'] ?? '';

        var messageData = latestMessage.data() as Map<String, dynamic>?;
        String lastMessage = messageData?['content'] ?? messageData?['replyMessage'] ?? 'No message content';
        var timestamp = messageData?['timestamp'] as Timestamp?;
        String lastMessageTime = timestamp != null
            ? DateFormat('MMM d, y • h:mm a').format(timestamp.toDate())
            : '';
        bool isNewMessage = messageData?['isNewForAdmin'] ?? false;
        bool isNewMessageFromAdmin = messageData?['isNewMessageFromAdmin'] ?? false;

        if (farmName == 'Unknown Farm') {
          return const SizedBox.shrink(); // Don't display anything for unknown farms
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: pondImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(pondImageUrl) as ImageProvider
                : null,
            child: pondImageUrl.isEmpty ? const Icon(Icons.agriculture, size: 30) : null,
          ),
          title: Text(
            farmName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isNewMessage || isNewMessageFromAdmin ? Colors.black : Colors.grey[600],
                  fontWeight: isNewMessage || isNewMessageFromAdmin ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lastMessageTime,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          trailing: isNewMessage || isNewMessageFromAdmin
              ? Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isNewMessageFromAdmin ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
            ),
          )
              : null,
          onTap: () async {
            // Mark all messages for this farm as read
            QuerySnapshot messages = await FirebaseFirestore.instance
                .collection('messages')
                .where('farmId', isEqualTo: farmId)
                .where('isNewMessageFromAdmin', isEqualTo: true)
                .get();

            WriteBatch batch = FirebaseFirestore.instance.batch();
            for (var doc in messages.docs) {
              batch.update(doc.reference, {'isNewMessageFromAdmin': false});
            }
            await batch.commit();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FarmMessageScreen(farmId: farmId, farmName: farmName),
              ),
            );
          },
        );
      },
    );
  }
}

