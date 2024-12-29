import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as devtools;
import '../fisher_reports_screen/fisher_reports_screen.dart';
import 'report_details_screen.dart';

class FishScanner extends StatefulWidget {
  final File initialImage;
  final String farmId;

  const FishScanner({
    Key? key,
    required this.initialImage,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FishScanner> createState() => _FishScannerState();
}

class _FishScannerState extends State<FishScanner> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool isAnalyzing = false;
  bool showResults = false;
  bool isLoading = true;
  Map<String, dynamic>? farmData;

  @override
  void initState() {
    super.initState();
    filePath = widget.initialImage;
    _tfLiteInit();
    _fetchFarmData();
  }

  Future<void> _fetchFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        Map<String, dynamic> data = farmDoc.data() as Map<String, dynamic>;
        setState(() {
          farmData = {
            'address': data['address'] ?? '',
            'barangay': data['barangay'] ?? '',
            'contactNumber': data['contactNumber'] ?? '',
            'createdAt': data['createdAt'] ?? '',
            'farmName': data['farmName'] ?? '',
            'feedTypes': data['feedTypes'] ?? '',
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'municipality': data['municipality'] ?? '',
            'numberOfCages': data['numberOfCages'] ?? 0,
            'pondImageUrl': data['pondImageUrl'] ?? '',
            'province': data['province'] ?? '',
            'region': data['region'] ?? '',
            'username': data['username'] ?? '',
          };

          if (data['fishTypes'] != null && data['fishTypes'] is List) {
            farmData!['fishTypes'] = (data['fishTypes'] as List).map((item) {
              return {
                'cageNumber': item['cageNumber'] ?? 0,
                'fishType': item['fishType'] ?? '',
              };
            }).toList();
          } else {
            farmData!['fishTypes'] = [];
          }

          if (data['last_location_update'] != null) {
            farmData!['last_location_update'] = (data['last_location_update'] as Timestamp).toDate();
          }
          if (data['last_status_update'] != null) {
            farmData!['last_status_update'] = (data['last_status_update'] as Timestamp).toDate();
          }

          if (data['realtime_location'] != null && data['realtime_location'] is GeoPoint) {
            GeoPoint geoPoint = data['realtime_location'] as GeoPoint;
            farmData!['realtime_location'] = [geoPoint.latitude, geoPoint.longitude];
          } else {
            farmData!['realtime_location'] = null;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error fetching farm data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _tfLiteInit() async {
    try {
      String? res = await Tflite.loadModel(
          model: "lib/models/model_unquant.tflite",
          labels: "lib/models/labels.txt",
          numThreads: 1,
          isAsset: true,
          useGpuDelegate: false
      );
      devtools.log('TFLite model loaded: $res');
    } catch (e) {
      devtools.log('Error loading TFLite model: $e');
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt, size: 32),
                          onPressed: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.camera);
                          },
                          color: const Color(0xFF40C4FF),
                        ),
                        const SizedBox(height: 8),
                        const Text('Camera'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library, size: 32),
                          onPressed: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.gallery);
                          },
                          color: const Color(0xFF40C4FF),
                        ),
                        const SizedBox(height: 8),
                        const Text('Gallery'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    setState(() {
      showResults = false;
      isAnalyzing = false;
    });

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      filePath = File(image.path);
    });
  }

  Future<void> analyzeImage() async {
    if (filePath == null) return;

    setState(() {
      isAnalyzing = true;
    });

    try {
      var recognitions = await Tflite.runModelOnImage(
          path: filePath!.path,
          imageMean: 0.0,
          imageStd: 255.0,
          numResults: 2,
          threshold: 0.2,
          asynch: true
      );

      if (recognitions == null) {
        devtools.log("recognitions is Null");
        setState(() {
          isAnalyzing = false;
        });
        return;
      }

      devtools.log(recognitions.toString());

      setState(() {
        confidence = (recognitions[0]['confidence'] * 100);
        label = recognitions[0]['label'].toString();
        isAnalyzing = false;
        showResults = true;
      });
    } catch (e) {
      devtools.log('Error analyzing image: $e');
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  Future<String> _uploadImageToStorage(File imageFile, String reportId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reports')
          .child('$reportId.jpg');

      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      devtools.log('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _createReport() async {
    if (filePath == null || farmData == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      final reportRef = await FirebaseFirestore.instance.collection('reports').add({
        'detection': label,
        'confidence': confidence,
        'timestamp': FieldValue.serverTimestamp(),
        'farmId': widget.farmId,
        'farmName': farmData!['farmName'],
        'ownerFirstName': farmData!['firstName'],
        'ownerLastName': farmData!['lastName'],
        'location': {
          'barangay': farmData!['barangay'],
          'municipality': farmData!['municipality'],
          'province': farmData!['province'],
          'region': farmData!['region'],
        },
        'realtime_location': farmData!['realtime_location'],
        'contactNumber': farmData!['contactNumber'],
        'feedTypes': farmData!['feedTypes'],
      });

      final imageUrl = await _uploadImageToStorage(filePath!, reportRef.id);
      await reportRef.update({'imageUrl': imageUrl});

      // Update the farm's status
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .update({
        'status': label.toLowerCase().contains('not likely detected')
            ? 'virusnotlikelydetected'
            : 'viruslikelydetected',
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailsScreen(
            reportId: reportRef.id,
            imageFile: filePath!,
            detection: label,
            farmData: {
              ...farmData!,
              'farmId': widget.farmId,
            },
          ),
        ),
      );
    } catch (e) {
      devtools.log('Error creating report: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create report')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Widget _buildImageContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF40C4FF), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(filePath!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (showResults) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF40C4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF40C4FF)),
            ),
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: label.toLowerCase().contains('not likely detected') ? Colors.green : Colors.red,
                  ),
                ),
                if (confidence > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _createReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40C4FF),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'REPORT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _showImageSourceDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40C4FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'RETAKE',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40C4FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'ANALYZE',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 40,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (showResults) {
              setState(() {
                showResults = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: isLoading && !isAnalyzing
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (showResults) const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'RESULTS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildImageContainer(),
          if (isAnalyzing) const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ANALYZING',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }
}

