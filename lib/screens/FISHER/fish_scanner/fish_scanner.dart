import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as devtools;
import 'report_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FishScanner extends StatefulWidget {
  final File initialImage;
  final String farmId;

  const FishScanner({
    super.key,
    required this.initialImage,
    required this.farmId,
  });

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
  bool _isMounted = false;

  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'Select Image Source': 'Pumili ng Pinagmulan ng Larawan',
      'Camera': 'Kamera',
      'Gallery': 'Galeri',
      'RETAKE': 'KUNAN MULI',
      'ANALYZE': 'SURIIN',
      'REPORT': 'MAG-ULAT',
      'RESULTS': 'MGA RESULTA',
      'ANALYZING': 'SINUSURI',
      'Confidence': 'Kumpiyansa',
      'Failed to create report': 'Hindi nagawa ang pag-uulat',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto mo bang ireport ito sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'HINDI',
      'Confirm Report': 'Kumpirma ang Ulat',
      'Do you want to proceed with this report?': 'Gusto mo bang magpatuloy sa ulat na ito?',
      'Cancel': 'Kanselahin',
      'Proceed': 'Magpatuloy',
    },
    'Bisaya': {
      'Select Image Source': 'Pagpili sa Tinubdan sa Hulagway',
      'Camera': 'Kamera',
      'Gallery': 'Galeri',
      'RETAKE': 'KUHAA PAGI',
      'ANALYZE': 'ANALISAR',
      'REPORT': 'IREPORT',
      'RESULTS': 'MGA RESULTA',
      'ANALYZING': 'GIANALISAR',
      'Confidence': 'Pagsalig',
      'Failed to create report': 'Napakyas sa paghimo og report',
      'Do you want to report it to Bureau of Fisheries and Aquatic Resources (BFAR)?': 'Gusto ba nimo ireport kini sa Bureau of Fisheries and Aquatic Resources (BFAR)?',
      'YES': 'OO',
      'NO': 'DILI',
      'Confirm Report': 'Kumpirma ang Report',
      'Do you want to proceed with this report?': 'Gusto ba nimong ipadayon kini nga report?',
      'Cancel': 'Kanselaha',
      'Proceed': 'Padayon',
    },
  };

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    filePath = widget.initialImage;
    _tfLiteInit();
    _fetchFarmData();
    _loadLanguagePreference();
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

  Future<void> _fetchFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists && _isMounted) {
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
      if (_isMounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                Text(
                  _getTranslatedText('Select Image Source'),
                  style: const TextStyle(
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
                        Text(_getTranslatedText('Camera')),
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
                        Text(_getTranslatedText('Gallery')),
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
    if (_isMounted) {
      setState(() {
        showResults = false;
        isAnalyzing = false;
      });
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    if (_isMounted) {
      setState(() {
        filePath = File(image.path);
      });
    }
  }

  Future<void> analyzeImage() async {
    if (filePath == null) return;

    if (_isMounted) {
      setState(() {
        isAnalyzing = true;
      });
    }

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
        if (_isMounted) {
          setState(() {
            isAnalyzing = false;
          });
        }
        return;
      }

      devtools.log(recognitions.toString());

      if (_isMounted) {
        setState(() {
          confidence = (recognitions[0]['confidence'] * 100);
          label = recognitions[0]['label'].toString();
          isAnalyzing = false;
          showResults = true;
        });
      }
    } catch (e) {
      devtools.log('Error analyzing image: $e');
      if (_isMounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }


  Future<void> _navigateToReportDetails() async {
    if (filePath == null || farmData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          imageFile: filePath!,
          detection: label,
          confidence: confidence,
          farmData: {
            ...farmData!,
            'farmId': widget.farmId,
          },
        ),
      ),
    );
  }

  Future<void> _showReportConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTranslatedText('Confirm Report'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF40C4FF),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.report_outlined,
                  size: 64,
                  color: Color(0xFF40C4FF),
                ),
                const SizedBox(height: 16),
                Text(
                  _getTranslatedText('Do you want to proceed with this report?'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        _getTranslatedText('Cancel'),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToReportDetails();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40C4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        _getTranslatedText('Proceed'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  String _getTranslatedText(String key) {
    if (_selectedLanguage == 'English') {
      return key;
    }
    return _translations[_selectedLanguage]?[key] ?? key;
  }

  @override
  void dispose() {
    _isMounted = false;
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
                    '${_getTranslatedText('Confidence')}: ${confidence.toStringAsFixed(1)}%',
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
            onPressed: _showReportConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40C4FF),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              _getTranslatedText('REPORT'),
              style: const TextStyle(color: Colors.white),
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
              child: Text(
                _getTranslatedText('RETAKE'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40C4FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                _getTranslatedText('ANALYZE'),
                style: const TextStyle(color: Colors.white),
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
          if (showResults) Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getTranslatedText('RESULTS'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildImageContainer(),
          if (isAnalyzing) Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getTranslatedText('ANALYZING'),
              style: const TextStyle(
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

