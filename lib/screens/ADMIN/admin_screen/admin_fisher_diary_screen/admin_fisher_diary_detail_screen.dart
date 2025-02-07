import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class AdminFishersDiaryDetailScreen extends StatefulWidget {
  final String farmId;
  final String diaryId;

  const AdminFishersDiaryDetailScreen({
    Key? key,
    required this.farmId,
    required this.diaryId,
  }) : super(key: key);

  @override
  State<AdminFishersDiaryDetailScreen> createState() => _AdminFishersDiaryDetailScreenState();
}

class _AdminFishersDiaryDetailScreenState extends State<AdminFishersDiaryDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadAndShareDiary() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      final diaryDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .collection('diary')
          .doc(widget.diaryId)
          .get();

      if (!farmDoc.exists || !diaryDoc.exists) {
        throw Exception('Farm or diary data not found');
      }

      final farmData = farmDoc.data()!;
      final diaryData = diaryDoc.data()!;
      final startDate = (diaryData['startDate'] as Timestamp).toDate();

      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Diary'];

      // Add farm info in the exact format shown
      sheet.appendRow([
        excel.TextCellValue('Farm Name:'),
        excel.TextCellValue(farmData['farmName'] ?? ''),
      ]);
      sheet.appendRow([
        excel.TextCellValue('Cage:'),
        excel.TextCellValue(diaryData['cageNumber'].toString()),
      ]);
      sheet.appendRow([
        excel.TextCellValue('Organism:'),
        excel.TextCellValue(diaryData['organism'] ?? ''),
      ]);
      sheet.appendRow([
        excel.TextCellValue('Status:'),
        excel.TextCellValue(diaryData['isHarvested'] == true ? 'Harvested' : 'Ongoing'),
      ]);

      sheet.appendRow([excel.TextCellValue('')]);  // Empty row for spacing

      // Add single header row
      final headers = [
        'Week No.',
        'Date',
        'Average body weight',
        'Average body length',
        '% Survival',
        'Water temperature (°C)',
        'pH level',
        'Salinity (ppt)',
        'Dissolved oxygen (ppm)',
        'Turbidity (%)',
        'Nitrite (ppm)',
        'Ammonia (ppm)',
      ];
      sheet.appendRow(headers.map((h) => excel.TextCellValue(h)).toList());

      // Calculate all weeks based on start date
      final harvestDate = (diaryData['harvestDate'] as Timestamp).toDate();
      final totalWeeks = ((harvestDate.difference(startDate).inDays) / 7).ceil();

      // Get weekly data
      final weeklyData = await diaryDoc.reference.collection('weekly_data').get();
      Map<int, Map<String, dynamic>> weekDataMap = {};

      // Create a map of week number to data
      for (var week in weeklyData.docs) {
        if (week.id == 'week_0') continue;  // Skip week 0
        final weekNum = int.parse(week.id.split('_')[1]);
        weekDataMap[weekNum] = week.data();
      }

      // Add all weeks (filled or empty) in order
      for (int weekNum = 1; weekNum <= totalWeeks; weekNum++) {
        final weekDate = startDate.add(Duration(days: 7 * (weekNum - 1)));
        final data = weekDataMap[weekNum] ?? {};

        sheet.appendRow([
          excel.TextCellValue(weekNum.toString()),
          excel.TextCellValue(DateFormat('MM/dd/yyyy').format(weekDate)),
          excel.TextCellValue(data['bodyWeight']?.toString() ?? ''),
          excel.TextCellValue(data['bodyLength']?.toString() ?? ''),
          excel.TextCellValue(data['survival']?.toString() ?? ''),
          excel.TextCellValue(data['waterTemp']?.toString() ?? ''),
          excel.TextCellValue(data['phLevel']?.toString() ?? ''),
          excel.TextCellValue(data['salinity']?.toString() ?? ''),
          excel.TextCellValue(data['dissolvedOxygen']?.toString() ?? ''),
          excel.TextCellValue(data['turbidity']?.toString() ?? ''),
          excel.TextCellValue(data['nitrite']?.toString() ?? ''),
          excel.TextCellValue(data['ammonia']?.toString() ?? ''),
        ]);
      }

      // Save the excel file
      final directory = await getTemporaryDirectory();
      final fileName = "Fisher_Diary_${farmData['farmName']}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(excelFile.encode()!);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'Fisher Diary Report');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary downloaded and ready to share')),
      );
    } catch (e) {
      print('Error downloading diary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading diary: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diary Entry Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF40C4FF),
        actions: [
          IconButton(
            icon: Icon(
              _isDownloading ? Icons.hourglass_empty : Icons.download,
              color: Colors.white,
            ),
            onPressed: _isDownloading ? null : _downloadAndShareDiary,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farms')
            .doc(widget.farmId)
            .collection('diary')
            .doc(widget.diaryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Diary entry not found.'));
          }

          final diaryData = snapshot.data!.data() as Map<String, dynamic>;
          final startDate = (diaryData['startDate'] as Timestamp).toDate();
          final harvestDate = (diaryData['harvestDate'] as Timestamp).toDate();
          final isHarvested = diaryData['isHarvested'] ?? false;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cage ${diaryData['cageNumber']} - ${diaryData['organism']}',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      if (isHarvested)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Harvested',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Date: ${DateFormat('MM/dd/yyyy').format(startDate)}',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  Text(
                    'Harvest Date: ${DateFormat('MM/dd/yyyy').format(harvestDate)}',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Weekly Data:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('farms')
                        .doc(widget.farmId)
                        .collection('diary')
                        .doc(widget.diaryId)
                        .collection('weekly_data')
                        .snapshots(),
                    builder: (context, weeklySnapshot) {
                      if (weeklySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (weeklySnapshot.hasError) {
                        return Center(child: Text('Error: ${weeklySnapshot.error}'));
                      }

                      if (!weeklySnapshot.hasData || weeklySnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No weekly data available.'),
                        );
                      }

                      final weeklyDocs = weeklySnapshot.data!.docs
                          .where((doc) => doc.id != 'week_0')
                          .toList()
                        ..sort((a, b) => int.parse(a.id.split('_')[1])
                            .compareTo(int.parse(b.id.split('_')[1])));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weeklyDocs.length,
                        itemBuilder: (context, index) {
                          final weekDoc = weeklyDocs[index];
                          final weekData = weekDoc.data() as Map<String, dynamic>;
                          final weekNumber = int.parse(weekDoc.id.split('_')[1]);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week $weekNumber',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Average Body Weight: ${weekData['bodyWeight']} g'),
                                  Text('Average Body Length: ${weekData['bodyLength']} cm'),
                                  Text('Survival Rate: ${weekData['survival']}%'),
                                  Text('Water Temperature: ${weekData['waterTemp']}°C'),
                                  Text('pH Level: ${weekData['phLevel']}'),
                                  Text('Salinity: ${weekData['salinity']} ppt'),
                                  Text('Dissolved Oxygen: ${weekData['dissolvedOxygen']} ppm'),
                                  Text('Turbidity: ${weekData['turbidity']}%'),
                                  Text('Nitrite: ${weekData['nitrite']} ppm'),
                                  Text('Ammonia: ${weekData['ammonia']} ppm'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

