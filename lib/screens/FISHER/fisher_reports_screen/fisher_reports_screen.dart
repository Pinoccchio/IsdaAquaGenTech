import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './report-detail-screen.dart';
import 'fisher_report_notification_screen.dart';
import 'package:geocoding/geocoding.dart';

class FisherReportsScreen extends StatefulWidget {
  final String farmId;

  const FisherReportsScreen({Key? key, required this.farmId}) : super(key: key);

  @override
  _FisherReportsScreenState createState() => _FisherReportsScreenState();
}

class _FisherReportsScreenState extends State<FisherReportsScreen> {
  Future<String> _getLocationDescription(List<dynamic>? coordinates) async {
    if (coordinates != null && coordinates.length == 2) {
      final lat = coordinates[0];
      final lng = coordinates[1];

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String street = place.street ?? '';
          String locality = place.locality ?? '';
          return '${street.isNotEmpty ? '$street, ' : ''}$locality'.trim();
        }
      } catch (e) {
        print('Error fetching location details: $e');
      }
    }
    return 'Location unavailable';
  }

  Stream<QuerySnapshot> _getReportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: widget.farmId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _navigateToDetail(BuildContext context, DocumentSnapshot report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isReplied, String detection) {
    if (isReplied) {
      return const Icon(Icons.check_circle, color: Colors.blue, size: 16);
    } else {
      final color = detection.toLowerCase().contains('not likely detected')
          ? Colors.green
          : Colors.red;
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportNotificationScreen(farmId: widget.farmId),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'REPORTS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildTableHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reports found.', style: TextStyle(fontSize: 16)));
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final data = report.data() as Map<String, dynamic>;
                      final timestamp = data['timestamp'] as Timestamp;
                      final dateTime = DateFormat('MM/dd/yyyy\nh:mm a').format(timestamp.toDate());
                      final detection = data['detection'] ?? 'Unknown';
                      final realtime_location = data['realtime_location'] as List<dynamic>?;
                      final isReplied = data['isReplied'] as bool? ?? false;

                      return FutureBuilder<String>(
                        future: _getLocationDescription(realtime_location),
                        builder: (context, locationSnapshot) {
                          final locationDescription = locationSnapshot.data ?? 'Fetching location...';

                          return GestureDetector(
                            onTap: () => _navigateToDetail(context, report),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF40C4FF)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: _buildStatusIndicator(isReplied, detection),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              data['farmName'] ?? 'Unknown Farm',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              locationDescription,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              dateTime,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              detection.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: detection.toLowerCase().contains('not likely detected')
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: const [
          SizedBox(
            width: 40,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'FARM NAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'LOCATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DATE/TIME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DETECTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

