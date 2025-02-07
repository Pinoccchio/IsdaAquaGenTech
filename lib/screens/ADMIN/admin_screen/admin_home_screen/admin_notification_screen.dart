import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_request_details_screen.dart';
import 'dart:async';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  _AdminNotificationsScreenState createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late StreamController<List<Map<String, dynamic>>> _streamController;
  List<Map<String, dynamic>> _editRequests = [];
  List<Map<String, dynamic>> _adminNotifications = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<Map<String, dynamic>>>();
    _initStreams();
  }

  @override
  void dispose() {
    _streamController.close();
    _timer?.cancel();
    super.dispose();
  }

  void _initStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Listen to edit requests
      FirebaseFirestore.instance
          .collection('edit_requests')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        _processEditRequests(snapshot);
      });

      // Listen to admin notifications
      FirebaseFirestore.instance
          .collection('USERS')
          .doc(user.uid)
          .collection('admin_notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        _processAdminNotifications(snapshot);
      });

      // Periodically combine and emit the latest data
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _emitCombinedData();
      });
    }
  }

  void _processEditRequests(QuerySnapshot snapshot) async {
    _editRequests = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      String farmName = 'Unknown Farm';
      try {
        final farmDoc = await FirebaseFirestore.instance
            .collection('farms')
            .doc(data['farmId'])
            .get();
        if (farmDoc.exists) {
          final farmData = farmDoc.data();
          farmName = farmData?['farmName'] ?? 'Unknown Farm';
        }
      } catch (e) {
        print('Error fetching farm data: $e');
      }
      return {
        ...data,
        'id': doc.id,
        'isEditRequest': true,
        'farmName': farmName,
        'isNewForAdmin': data['isNewForAdmin'] ?? false,
      };
    }));
    _emitCombinedData();
  }

  void _processAdminNotifications(QuerySnapshot snapshot) {
    _adminNotifications = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id,
        'isEditRequest': false,
        'isNew': data['isNew'] ?? false,
      };
    }).toList();
    _emitCombinedData();
  }

  void _emitCombinedData() {
    final combined = [..._editRequests, ..._adminNotifications];
    combined.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });
    _streamController.add(combined);
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  Future<void> _navigateToEditRequestDetails(String farmId, String requestId) async {
    final editRequestDetailsScreen = EditRequestDetailsScreen(farmId: farmId, requestId: requestId);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => editRequestDetailsScreen,
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final status = result['status'];
      final farmName = result['farmName'];

      // Update the edit request status in the local list
      setState(() {
        _editRequests = _editRequests.map((request) {
          if (request['id'] == requestId) {
            return {...request, 'status': status};
          }
          return request;
        }).toList();
      });

      // Refresh the notifications
      _initStreams();
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final bool isEditRequest = notification['isEditRequest'];
    if (isEditRequest) {
      await FirebaseFirestore.instance
          .collection('edit_requests')
          .doc(notification['id'])
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('USERS')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('admin_notifications')
          .doc(notification['id'])
          .delete();
    }
  }

  Future<void> _updateNewStatus(String id, bool isEditRequest) async {
    if (isEditRequest) {
      await FirebaseFirestore.instance
          .collection('edit_requests')
          .doc(id)
          .update({'isNewForAdmin': false});
    } else {
      await FirebaseFirestore.instance
          .collection('USERS')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('admin_notifications')
          .doc(id)
          .update({'isNewForAdmin': false});
    }
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final bool isEditRequest = notification['isEditRequest'];
    final String status = notification['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: (isEditRequest && notification['isNewForAdmin'] == true) ||
            (!isEditRequest && notification['isNewForAdmin'] == true)
            ? Colors.blue[50]
            : Colors.white,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                isEditRequest
                    ? 'Edit Request for ${notification['farmName']}'
                    : notification['message'] ?? 'No message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ((isEditRequest && notification['isNewForAdmin'] == true) ||
                      (!isEditRequest && notification['isNewForAdmin'] == true))
                      ? Colors.blue[800]
                      : Colors.black,
                ),
              ),
            ),
            if ((isEditRequest && notification['isNewForAdmin'] == true) ||
                (!isEditRequest && notification['isNewForAdmin'] == true))
              Icon(Icons.fiber_new, color: Colors.blue[800]),
            if (status != 'pending')
              Icon(
                status == 'approved' ? Icons.check_circle : Icons.cancel,
                color: status == 'approved' ? Colors.green : Colors.red,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimestamp(notification['timestamp'] as Timestamp?),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (isEditRequest)
              Text(
                'Status: ${status.capitalize()}',
                style: TextStyle(
                  color: status == 'pending' ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () {
          if (isEditRequest) {
            if (isEditRequest && notification['isNewForAdmin'] == true) {
              _updateNewStatus(notification['id'], true);
            }
            _navigateToEditRequestDetails(notification['farmId'], notification['id']);
          } else {
            if (!isEditRequest && notification['isNewForAdmin'] == true) {
              _updateNewStatus(notification['id'], false);
            }
            // Handle tapping on admin notifications if needed
          }
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          return CustomScrollView(
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
              notifications.isEmpty
                  ? SliverFillRemaining(
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
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final notification = notifications[index];


                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Dismissible(
                        key: Key(notification['id']),
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
                        onDismissed: (direction) => _deleteNotification(notification),
                        child: _buildNotificationTile(notification),
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

