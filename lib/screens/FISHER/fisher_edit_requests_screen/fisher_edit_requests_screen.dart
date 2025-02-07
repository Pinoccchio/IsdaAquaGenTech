import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FisherEditRequestsScreen extends StatefulWidget {
  final String farmId;

  const FisherEditRequestsScreen({
    super.key,
    required this.farmId,
  });

  @override
  _FisherEditRequestsScreenState createState() => _FisherEditRequestsScreenState();
}

class _FisherEditRequestsScreenState extends State<FisherEditRequestsScreen> {
  late Future<DocumentSnapshot> _farmFuture;
  late StreamController<Map<String, dynamic>> _streamController;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<Map<String, dynamic>>();
    _farmFuture = FirebaseFirestore.instance.collection('farms').doc(widget.farmId).get();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Widget _buildFishTypesWidget(dynamic currentValue, dynamic proposedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Fish Types:',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        _buildFishTypesList(currentValue),
        const SizedBox(height: 8),
        Text(
          'Proposed Fish Types:',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue[600]),
        ),
        _buildFishTypesList(proposedValue),
      ],
    );
  }

  Widget _buildFishTypesList(dynamic fishTypes) {
    if (fishTypes is! List) {
      return const Text('No fish types data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fishTypes.map((fishType) {
        if (fishType is Map<String, dynamic>) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Row(
              children: [
                Text('Cage ${fishType['cageNumber']}: '),
                Text(
                  (fishType['fishTypes'] as List<dynamic>).join(', '),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Request Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue[800],
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: FutureBuilder(
        future: _farmFuture,
        builder: (context, AsyncSnapshot<DocumentSnapshot> farmSnapshot) {
          if (farmSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (farmSnapshot.hasError) {
            return Center(child: Text('Error: ${farmSnapshot.error}'));
          }

          final farmData = farmSnapshot.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('edit_requests')
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

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No edit requests found'));
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farm: ${farmData['farmName']}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Edit Requests',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        var editRequest = snapshot.data!.docs[index];
                        return _buildEditRequestCard(editRequest, farmData);
                      },
                      childCount: snapshot.data!.docs.length,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditRequestCard(DocumentSnapshot editRequest, Map<String, dynamic> farmData) {
    Map<String, dynamic> data = editRequest.data() as Map<String, dynamic>;
    String status = data['status'] ?? 'pending';
    DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
    Map<String, dynamic> requestedChanges = data['requestedChanges'] as Map<String, dynamic>;
    bool isNew = data['isNew'] ?? false;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              'Edit Request',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            if (isNew)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text(
          _formatTimestamp(data['timestamp']),
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: requestedChanges.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      entry.key == 'fishTypes'
                          ? _buildFishTypesWidget(farmData[entry.key], entry.value)
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${farmData[entry.key]}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Proposed:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[600],
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          if (expanded && isNew) {
            FirebaseFirestore.instance
                .collection('edit_requests')
                .doc(editRequest.id)
                .update({'isNew': false});
          }
        },
      ),
    );
  }
}
