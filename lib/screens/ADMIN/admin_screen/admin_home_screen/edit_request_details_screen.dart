import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EditRequestDetailsScreen extends StatefulWidget {
  final String farmId;
  final String requestId;

  const EditRequestDetailsScreen({
    super.key,
    required this.farmId,
    required this.requestId,
  });

  @override
  _EditRequestDetailsScreenState createState() => _EditRequestDetailsScreenState();
}

class _EditRequestDetailsScreenState extends State<EditRequestDetailsScreen> {
  late Future<DocumentSnapshot> _farmFuture;
  late Future<DocumentSnapshot> _requestFuture;
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
    _requestFuture = FirebaseFirestore.instance.collection('edit_requests').doc(widget.requestId).get();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Future<void> _handleRequest(bool approve) async {
    try {
      final requestDoc = await _requestFuture;
      final requestData = requestDoc.data() as Map<String, dynamic>;

      if (requestData['status'] == 'approved' || requestData['status'] == 'rejected') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This request has already been ${requestData['status']}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final requestedChanges = requestData['requestedChanges'] as Map<String, dynamic>;

      if (approve) {
        await FirebaseFirestore.instance.collection('farms').doc(widget.farmId).update(requestedChanges);
      }

      final status = approve ? 'approved' : 'rejected';
      await FirebaseFirestore.instance.collection('edit_requests').doc(widget.requestId).update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Create a new message
      final messageId = const Uuid().v4();
      await FirebaseFirestore.instance.collection('messages').doc(messageId).set({
        'farmId': widget.farmId,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'admin',
        'replyMessage': 'Your edit request has been $status.',
        'isNew': true,
        'isNewForAdmin': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Edit request $status successfully'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );

      final farmDoc = await _farmFuture;
      final farmData = farmDoc.data() as Map<String, dynamic>;
      final farmName = farmData['farmName'] as String;

      if (!_streamController.isClosed) {
        _streamController.add({'status': status, 'farmName': farmName});
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error processing edit request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing edit request'), backgroundColor: Colors.red),
      );
    }
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
        future: Future.wait([_farmFuture, _requestFuture]),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final farmData = snapshot.data![0].data() as Map<String, dynamic>;
          final requestData = snapshot.data![1].data() as Map<String, dynamic>;
          final requestedChanges = requestData['requestedChanges'] as Map<String, dynamic>;

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
                        'Requested Changes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(requestData['timestamp'] as Timestamp?),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final entry = requestedChanges.entries.elementAt(index);
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
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: entry.key == 'fishTypes'
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
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: requestedChanges.length,
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<DocumentSnapshot>(
                  future: _requestFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final requestData = snapshot.data!.data() as Map<String, dynamic>;
                    final bool isProcessed = requestData['status'] == 'approved' || requestData['status'] == 'rejected';

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isProcessed ? null : () => _handleRequest(true),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isProcessed ? null : () => _handleRequest(false),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

