import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_report_detail_screen.dart';

class AdminReportNotificationScreen extends StatelessWidget {
  const AdminReportNotificationScreen({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('isReplied', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _navigateToDetail(BuildContext context, DocumentSnapshot report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No new notifications.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp;
              final dateTime = DateFormat('MMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());

              return ListTile(
                title: Text('New report from ${data['farmName']}'),
                subtitle: Text('$dateTime\n${data['detection']}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToDetail(context, notification),
              );
            },
          );
        },
      ),
    );
  }
}

