import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final DocumentSnapshot report;

  const AdminReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _AdminReportDetailScreenState createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  late Map<String, dynamic> reportData;
  String? replyMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    reportData = widget.report.data() as Map<String, dynamic>;
    _fetchReplyMessage();
  }

  Future<void> _fetchReplyMessage() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('reportId', isEqualTo: widget.report.id)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final latestMessage = querySnapshot.docs.first.data();
        setState(() {
          replyMessage = latestMessage['replyMessage'] as String?;
          isLoading = false;
        });
      } else {
        setState(() {
          replyMessage = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching reply message: $e');
      setState(() {
        replyMessage = null;
        isLoading = false;
      });
    }
  }

  Widget _buildStatusIndicator(String detection) {
    final isLikelyDetected = detection.toLowerCase().contains('likely detected') &&
        !detection.toLowerCase().contains('not likely detected');
    final color = isLikelyDetected ? Colors.red : Colors.green;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = reportData['timestamp'] as Timestamp;
    final dateTime = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reportData['imageUrl'] != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(reportData['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusIndicator(reportData['detection']),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reportData['detection'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: reportData['detection'].toLowerCase().contains('not likely detected')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${reportData['confidence'].toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF40C4FF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reportData['farmName']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner: ${reportData['ownerFirstName']} ${reportData['ownerLastName']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Contact: ${reportData['contactNumber']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Feed Types: ${reportData['feedTypes']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reportData['location']['barangay']}, ${reportData['location']['municipality']},\n${reportData['location']['province']}, ${reportData['location']['region']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reported on $dateTime',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'REPLY MESSAGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (replyMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF40C4FF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        replyMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'No reply message available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

