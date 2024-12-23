import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  _AdminNotificationsScreenState createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initNotificationsStream();
  }

  void _initNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('USERS')
          .doc(user.uid)
          .collection('admin_notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('USERS')
          .doc(user.uid)
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'read': true});
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final notification = notifications[index];
                    final data = notification.data() as Map<String, dynamic>;
                    final bool isRead = data['read'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Dismissible(
                        key: Key(notification.id),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await FirebaseFirestore.instance
                              .collection('USERS')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('admin_notifications')
                              .doc(notification.id)
                              .delete();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(
                              data['message'] ?? 'No message',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _formatTimestamp(data['timestamp'] as Timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: isRead
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                              onPressed: () => _markAsRead(notification.id),
                            ),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(notification.id);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _initNotificationsStream();
          });
        },
        child: const Icon(Icons.refresh, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

