import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'admin_fisher_diary_detail_screen.dart';

class AdminFishersDiaryScreen extends StatefulWidget {
  const AdminFishersDiaryScreen({Key? key}) : super(key: key);

  @override
  State<AdminFishersDiaryScreen> createState() => _AdminFishersDiaryScreenState();
}

class _AdminFishersDiaryScreenState extends State<AdminFishersDiaryScreen> {
  bool _isDownloading = false;

  Future<void> _downloadAndShareDiaries() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final excelFile = excel.Excel.createExcel();
      final farms = await FirebaseFirestore.instance.collection('farms').get();

      for (var farm in farms.docs) {
        final farmData = farm.data();
        final farmName = farmData['farmName'] ?? 'Unnamed Farm';

        // Get diary entries for this farm
        final diaryEntries = await farm.reference.collection('diary').get();

        for (var entry in diaryEntries.docs) {
          final diaryData = entry.data();
          final startDate = (diaryData['startDate'] as Timestamp).toDate();
          final harvestDate = (diaryData['harvestDate'] as Timestamp).toDate();

          // Create a new sheet for each diary entry
          final sheetName = '${farmName}_Cage${diaryData['cageNumber']}';
          final sheet = excelFile[sheetName];

          // Add farm info in the exact format shown
          sheet.appendRow([
            excel.TextCellValue('Farm Name:'),
            excel.TextCellValue(farmName),
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

          // Calculate total weeks
          final totalWeeks = ((harvestDate.difference(startDate).inDays) / 7).ceil();

          // Get weekly data
          final weeklyData = await entry.reference.collection('weekly_data').get();
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
        }
      }

      // Save the excel file
      final directory = await getTemporaryDirectory();
      final fileName = "Fisher_Diaries_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(excelFile.encode()!);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'Fisher Diaries Report');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diaries downloaded and ready to share')),
      );
    } catch (e) {
      print('Error downloading diaries: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading diaries: $e')),
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
          'Fisherman\'s Diaries',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF40C4FF),
        actions: [
          IconButton(
            icon: Icon(
              _isDownloading ? Icons.hourglass_empty : Icons.download,
              color: Colors.white,
            ),
            onPressed: _isDownloading ? null : _downloadAndShareDiaries,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('farms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No farms found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final farm = snapshot.data!.docs[index];
              final farmData = farm.data() as Map<String, dynamic>;
              return ExpansionTile(
                title: Text(farmData['farmName'] ?? 'Unnamed Farm'),
                subtitle: Text('Owner: ${farmData['firstName'] ?? ''} ${farmData['lastName'] ?? ''}'),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('farms')
                        .doc(farm.id)
                        .collection('diary')
                        .orderBy('startDate', descending: true)
                        .snapshots(),
                    builder: (context, diarySnapshot) {
                      if (diarySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!diarySnapshot.hasData || diarySnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No diary entries found.'),
                        );
                      }

                      return Column(
                        children: diarySnapshot.data!.docs.map((entry) {
                          final entryData = entry.data() as Map<String, dynamic>;
                          final startDate = (entryData['startDate'] as Timestamp).toDate();
                          final harvestDate = (entryData['harvestDate'] as Timestamp).toDate();
                          final isHarvested = entryData['isHarvested'] ?? false;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF40C4FF)),
                              borderRadius: BorderRadius.circular(8),
                              color: isHarvested ? Colors.green[50] : null,
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text('Cage ${entryData['cageNumber']} - ${entryData['organism']}'),
                                  const SizedBox(width: 8),
                                  if (isHarvested)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Harvested',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${DateFormat('MM/dd/yyyy').format(startDate)} - ${DateFormat('MM/dd/yyyy').format(harvestDate)}',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminFishersDiaryDetailScreen(
                                      farmId: farm.id,
                                      diaryId: entry.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

