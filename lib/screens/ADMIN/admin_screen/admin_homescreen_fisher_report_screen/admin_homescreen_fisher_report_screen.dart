import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_homescreen_fisher_detailed_screen.dart';

class AdminHomescreenFisherReportScreen extends StatefulWidget {
  final String farmId;

  const AdminHomescreenFisherReportScreen({super.key, required this.farmId});

  @override
  _AdminHomescreenFisherReportScreenState createState() => _AdminHomescreenFisherReportScreenState();
}

class _AdminHomescreenFisherReportScreenState extends State<AdminHomescreenFisherReportScreen> {
  List<Map<String, dynamic>> _farmReports = [];
  bool _isLoading = true;
  String _farmName = '';

  @override
  void initState() {
    super.initState();
    _loadFarmData();
    _listenToReports();
  }

  Future<void> _loadFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        setState(() {
          _farmName = farmDoc['farmName'] ?? 'Unknown Farm';
        });
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  void _listenToReports() {
    FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: widget.farmId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _farmReports = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'timestamp': data['timestamp'],
              'detection': data['detection'],
              'farmName': data['farmName'],
              'ownerFirstName': data['ownerFirstName'],
              'ownerLastName': data['ownerLastName'],
              'farmId': data['farmId'],
              'status': data['status'] ?? 'normal',
              'isReplied': data['isReplied'] ?? false,
              'imageUrl': data['imageUrl'],
              'confidence': data['confidence'],
              'contactNumber': data['contactNumber'],
              'feedTypes': data['feedTypes'],
              'realtime_location': data['realtime_location'],
              'isNewForAdmin': data['isNewForAdmin'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error listening to reports: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.month}/${date.day}/${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

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
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _farmName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF40C4FF),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _farmReports.isEmpty
                ? const Center(child: Text('No reports found for this farm.'))
                : ListView.builder(
              itemCount: _farmReports.length,
              itemBuilder: (context, index) {
                final report = _farmReports[index];
                final detection = report['detection'] as String? ?? 'Unknown';
                final isDiseaseDetected = detection.toUpperCase().contains('LIKELY DETECTED') &&
                    !detection.toUpperCase().contains('NOT LIKELY DETECTED');
                final isNewForAdmin = report['isNewForAdmin'] ?? false;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminHomescreenFisherDetailedScreen(
                          reportId: report['id'],
                          reportData: report,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF40C4FF)),
                      borderRadius: BorderRadius.circular(12),
                      color: isNewForAdmin ? const Color(0xFFE3F2FD) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: report['isReplied'] == true
                                ? Colors.blue
                                : isDiseaseDetected
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTimestamp(report['timestamp'] as Timestamp),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detection.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDiseaseDetected ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

