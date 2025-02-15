import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'admin_report_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';


class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isDownloading = false;

  Stream<QuerySnapshot> _getReportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Widget _buildStatusIndicator(String detection) {
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


  Future<String> _getLocationDescription(Map<String, dynamic> reportData) async {
    if (reportData['realtime_location'] != null) {
      final lat = reportData['realtime_location'][0];
      final lng = reportData['realtime_location'][1];

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        } else {
          return 'Location details not available';
        }
      } catch (e) {
        print('Error fetching location details: $e');
        return 'Error fetching location details';
      }
    } else {
      return 'Location data not available';
    }
  }

  Future<void> _downloadAndShareReports() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final excelFile = excel.Excel.createExcel();
      final shrimpLikelySheet = excelFile['Shrimp Disease Likely Detected'];
      final shrimpNotLikelySheet = excelFile['Shrimp Disease Not Likely Detected'];
      final tilapiaLikelySheet = excelFile['Tilapia Disease Likely Detected'];
      final tilapiaNotLikelySheet = excelFile['Tilapia Disease Not Likely Detected'];

      // Add headers to all sheets
      final headers = ['Farm Name', 'Date', 'Detection', 'Location', 'Image URL', 'Owner Name', 'Contact Number', 'Feed Types', 'Reported to BFAR'];
      for (var sheet in [shrimpLikelySheet, shrimpNotLikelySheet, tilapiaLikelySheet, tilapiaNotLikelySheet]) {
        sheet.appendRow(headers.map((e) => excel.TextCellValue(e)).toList());
      }

      // Fetch all reports
      final reports = await FirebaseFirestore.instance.collection('reports').get();

      for (var doc in reports.docs) {
        final data = doc.data();
        final locationDescription = await _getLocationDescription(data);
        final detection = data['detection'] ?? 'Unknown';
        final isDiseaseDetected = !detection.toLowerCase().contains('not likely detected');
        final isShrimp = detection.toLowerCase().contains('shrimp');

        final rowData = [
          data['farmName'] ?? 'Unknown',
          DateFormat('MM/dd/yy hh:mm a').format((data['timestamp'] as Timestamp).toDate()),
          detection,
          locationDescription,
          data['imageUrl'] ?? 'No image',
          '${data['ownerFirstName'] ?? ''} ${data['ownerLastName'] ?? ''}',
          data['contactNumber'] ?? 'Unknown',
          data['feedTypes'] ?? 'Unknown',
          data['reportedToBFAR'] == true ? 'Yes' : 'No'
        ].map((e) => excel.TextCellValue(e.toString())).toList();

        if (isShrimp) {
          if (isDiseaseDetected) {
            shrimpLikelySheet.appendRow(rowData);
          } else {
            shrimpNotLikelySheet.appendRow(rowData);
          }
        } else {
          if (isDiseaseDetected) {
            tilapiaLikelySheet.appendRow(rowData);
          } else {
            tilapiaNotLikelySheet.appendRow(rowData);
          }
        }
      }

      // Save the excel file to app's temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = "ISDA_Reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(excelFile.encode()!);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'ISDA Reports');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports downloaded and ready to share')),
      );
    } catch (e) {
      print('Error downloading reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading reports: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'STATUS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'FARM NAME',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'LOCATION',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'DATE/TIME',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'DETECTION',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(BuildContext context, DocumentSnapshot report) {
    final data = report.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp;
    final dateTime = DateFormat('MM/dd/yy\nh:mm a').format(timestamp.toDate());
    final detection = data['detection'] ?? 'Unknown';
    final isNewForAdmin = data['isNewForAdmin'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF40C4FF)),
          borderRadius: BorderRadius.circular(12),
          color: isNewForAdmin ? Colors.blue[50] : null,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: _buildStatusIndicator(detection),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  data['farmName'] ?? 'Unknown Farm',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: FutureBuilder<String>(
                  future: _getLocationDescription(data),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Fetching location...',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  dateTime,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  detection.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: detection.toLowerCase().contains('not likely detected')
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            icon: Icon(_isDownloading ? Icons.hourglass_empty : Icons.share, color: Colors.black),
            onPressed: _isDownloading ? null : _downloadAndShareReports,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'ALL REPORTS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            _buildTableHeader(),
            const SizedBox(height: 16),
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
                    itemCount: reports.length,
                    itemBuilder: (context, index) => _buildReportRow(context, reports[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

