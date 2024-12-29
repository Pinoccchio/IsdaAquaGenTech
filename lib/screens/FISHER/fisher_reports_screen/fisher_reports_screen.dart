import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class FisherReportsScreen extends StatefulWidget {
  final String farmId;

  const FisherReportsScreen({Key? key, required this.farmId}) : super(key: key);

  @override
  _FisherReportsScreenState createState() => _FisherReportsScreenState();
}

class _FisherReportsScreenState extends State<FisherReportsScreen> {
  late Stream<QuerySnapshot> _reportsStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = _getReportsStream();
  }

  Stream<QuerySnapshot> _getReportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: widget.farmId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsStream = _getReportsStream();
    });
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Unknown Location";
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
              // Handle notification tap
            },
          ),
        ],
      ),
      body: Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'FARM NAME',
                    style: TextStyle(
                      fontSize: 10,
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
                      fontSize: 10,
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
                      fontSize: 10,
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshReports,
              color: Colors.blue,
              child: StreamBuilder<QuerySnapshot>(
                stream: _reportsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reports found.'));
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index].data() as Map<String, dynamic>;
                      final timestamp = report['timestamp'] as Timestamp;
                      final dateTime = DateFormat('MM/dd/yyyy\nh:mm a').format(timestamp.toDate());
                      final detection = report['detection'] ?? 'Unknown';
                      final realtime_location = report['realtime_location'] as List<dynamic>?;

                      double? latitude;
                      double? longitude;

                      if (realtime_location != null && realtime_location.length == 2) {
                        latitude = realtime_location[0] as double?;
                        longitude = realtime_location[1] as double?;
                      }

                      return FutureBuilder<String>(
                        future: (latitude != null && longitude != null)
                            ? _getAddressFromCoordinates(latitude, longitude)
                            : Future.value('Unknown Location'),
                        builder: (context, addressSnapshot) {
                          final address = addressSnapshot.data ?? 'Loading...';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF40C4FF)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(left: 12, right: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: report['status'] == 'pending'
                                        ? Colors.orange
                                        : detection.toLowerCase().contains('not likely detected')
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            report['farmName'] ?? 'Unknown Farm',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            address,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            dateTime,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            detection.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
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
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

