import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('admin_notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: Text(
              '${snapshot.data!.docs.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

