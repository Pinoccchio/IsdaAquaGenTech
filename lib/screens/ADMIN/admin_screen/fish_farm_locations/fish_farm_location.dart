import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class FishFarmLocationScreen extends StatefulWidget {
  const FishFarmLocationScreen({Key? key}) : super(key: key);

  @override
  _FishFarmLocationScreenState createState() => _FishFarmLocationScreenState();
}

class _FishFarmLocationScreenState extends State<FishFarmLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _unreadNotifications = 0;
  String? _selectedFarmId;
  List<Map<String, dynamic>> _farmReports = [];
  bool _isReplying = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _selectedTime = TimeOfDay.now();

  static final LatLngBounds philippinesBounds = LatLngBounds(
    southwest: const LatLng(4.2259, 116.9282),
    northeast: const LatLng(21.3217, 126.6000),
  );

  @override
  void initState() {
    super.initState();
    _listenToReports();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadNotifications = snapshot.docs.length;
      });
    });
  }

  BitmapDescriptor _getMarkerIcon(String detection, String status, bool isReplied) {
    if (isReplied) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else if (status == 'urgent' || (detection.toUpperCase().contains('LIKELY DETECTED') &&
        !detection.toUpperCase().contains('NOT LIKELY DETECTED'))) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<String> _getLocationDescription(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
    } catch (e) {
      print('Error fetching location details: $e');
    }
    return 'Location details not available';
  }

  void _listenToReports() {
    FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final Map<String, List<DocumentSnapshot>> farmReports = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final farmId = data['farmId'] as String?;
        if (farmId != null) {
          if (!farmReports.containsKey(farmId)) {
            farmReports[farmId] = [];
          }
          farmReports[farmId]!.add(doc);
        }
      }

      setState(() {
        _markers.clear();
      });

      for (var farmId in farmReports.keys) {
        final latestReport = farmReports[farmId]!.first;
        final data = latestReport.data() as Map<String, dynamic>;

        if (data['realtime_location'] != null) {
          final location = data['realtime_location'] as List<dynamic>;
          final lat = location[0] as double;
          final lng = location[1] as double;

          String locationDescription = await _getLocationDescription(lat, lng);

          setState(() {
            final marker = Marker(
              markerId: MarkerId(farmId),
              position: LatLng(lat, lng),
              icon: _getMarkerIcon(
                  data['detection'] ?? '',
                  data['status'] ?? 'normal',
                  data['isReplied'] ?? false
              ),
              infoWindow: InfoWindow(
                title: data['farmName'] ?? 'Unnamed Farm',
                snippet: 'Tap to view reports',
              ),
              onTap: () => _showFarmReports(farmId, farmReports[farmId]!, locationDescription),
            );
            _markers.add(marker);
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reports: $error';
      });
    });
  }

  void _showFarmReports(String farmId, List<DocumentSnapshot> reports, String locationDescription) {
    setState(() {
      _selectedFarmId = farmId;
      _farmReports = reports.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'timestamp': data['timestamp'],
          'detection': data['detection'],
          'farmName': data['farmName'],
          'ownerFirstName': data['ownerFirstName'],
          'ownerLastName': data['ownerLastName'],
          'locationDescription': locationDescription,
          'farmId': data['farmId'],
          'status': data['status'] ?? 'normal',
          'isReplied': data['isReplied'] ?? false,
          'imageUrl': data['imageUrl'],
          'confidence': data['confidence'],
          'contactNumber': data['contactNumber'],
          'feedTypes': data['feedTypes'],
          'location': data['location'],
        };
      }).toList();
    });
  }

  void _closeFarmReports() {
    setState(() {
      _selectedFarmId = null;
      _farmReports.clear();
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.month}/${date.day}/${date.year} ${hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showMessageAlert(Map<String, dynamic> report) async {
    final detection = report['detection'] ?? 'Unknown';
    final bool isVirusLikelyDetected = detection.toUpperCase().contains('LIKELY DETECTED') &&
        !detection.toUpperCase().contains('NOT LIKELY DETECTED');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MESSAGE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detection.toUpperCase()} AT ${report['farmName'] ?? 'UNKNOWN FARM'} (OWNER: ${report['ownerFirstName'] ?? ''} ${report['ownerLastName'] ?? ''})',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LOCATION: ${report['locationDescription'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TIMESTAMP: ${_formatTimestamp(report['timestamp'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isVirusLikelyDetected)
                        const Text(
                          'NEED IMMEDIATE ACTION!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        )
                      else
                        const Text(
                          'No immediate action required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isReplying ? null : () {
                      Navigator.of(context).pop();
                      _showReplyDialog(report);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isReplying
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'SEND MESSAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _getFormattedDateTime() {
    final date = DateFormat('MMMM d, yyyy').format(_selectedDate);
    final time = _selectedTime.format(context);
    return '$date at $time';
  }

  Future<void> _showReplyDialog(Map<String, dynamic> report) async {
    final detection = report['detection'] ?? 'Unknown';
    final bool isVirusLikelyDetected = detection.toUpperCase().contains('LIKELY DETECTED') &&
        !detection.toUpperCase().contains('NOT LIKELY DETECTED');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'MESSAGE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NEEDED ACTION:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isVirusLikelyDetected
                                      ? 'A SCIENTIST WILL VISIT YOUR FARM TO COLLECT SAMPLES FOR CONFIRMATORY TEST.'
                                      : 'NO IMMEDIATE ACTION REQUIRED. CONTINUE MONITORING YOUR FARM AND REPORT ANY CHANGES IN FISH HEALTH.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isVirusLikelyDetected) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'SELECT VISITATION DATE AND TIME:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context).then((_) => setState(() {})),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              DateFormat('MM/dd/yyyy').format(_selectedDate),
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context).then((_) => setState(() {})),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedTime.format(context),
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.access_time, color: Colors.blue, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Selected: ${_getFormattedDateTime()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final replyMessage = isVirusLikelyDetected
                                    ? 'A SCIENTIST WILL VISIT YOUR FARM TO COLLECT SAMPLES FOR CONFIRMATORY TEST.'
                                    : 'NO IMMEDIATE ACTION REQUIRED. CONTINUE MONITORING YOUR FARM AND REPORT ANY CHANGES IN FISH HEALTH.';
                                await _sendReply(report, replyMessage, isVirusLikelyDetected);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BFA5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'SEND MESSAGE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendReply(Map<String, dynamic> report, String replyMessage, bool isVirusLikelyDetected) async {
    try {
      final farmId = report['farmId'];
      final messageRef = FirebaseFirestore.instance.collection('messages').doc();
      await messageRef.set({
        'farmId': farmId,
        'replyMessage': replyMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'visitationDateTime': isVirusLikelyDetected ? _getFormattedDateTime() : null,
        'isVirusLikelyDetected': isVirusLikelyDetected,
        'detection': report['detection'] ?? 'Unknown',
        'confidence': report['confidence'] ?? 0.0,
        'farmName': report['farmName'] ?? 'Unknown Farm',
        'ownerFirstName': report['ownerFirstName'] ?? '',
        'ownerLastName': report['ownerLastName'] ?? '',
        'contactNumber': report['contactNumber'] ?? 'Unknown',
        'feedTypes': report['feedTypes'] ?? 'Unknown',
        'location': report['location'] ?? {},
        'imageUrl': report['imageUrl'] ?? '',
      });

      await FirebaseFirestore.instance.collection('reports').doc(report['id']).update({
        'isReplied': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }

  Widget _buildReportsList() {
    if (_selectedFarmId == null) return const SizedBox.shrink();

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Text(
              'FARM ${_selectedFarmId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _farmReports.length,
              itemBuilder: (context, index) {
                final report = _farmReports[index];
                final detection = report['detection'] as String? ?? 'Unknown';
                final status = report['status'] as String? ?? 'normal';
                final isVirusLikelyDetected = detection.toUpperCase().contains('LIKELY DETECTED') &&
                    !detection.toUpperCase().contains('NOT LIKELY DETECTED');

                return GestureDetector(
                  onTap: () => _showMessageAlert(report),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF40C4FF),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: report['isReplied'] == true
                                ? Colors.blue
                                : isVirusLikelyDetected
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ID# ${report['id']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatTimestamp(report['timestamp'] as Timestamp),
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
                              color: isVirusLikelyDetected ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
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

  Future<void> _centerMapOnPhilippines() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      philippinesBounds,
      50.0,
    ));
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    await controller.setMapStyle('''
      [
        {
          "featureType": "administrative.country",
          "elementType": "geometry",
          "stylers": [
            {
              "visibility": "simplified"
            }
          ]
        }
      ]
    ''');
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {
                  // Navigate to notifications
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text(
              'FISH FARM LOCATIONS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                color: Color(0xFF4A4A4A),
                fontFamily: 'Arial',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.8797, 121.7740),
              zoom: 5,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
            cameraTargetBounds: CameraTargetBounds(philippinesBounds),
            onTap: (_) => _closeFarmReports(),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildReportsList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 216),
        child: FloatingActionButton(
          onPressed: _centerMapOnPhilippines,
          backgroundColor: const Color(0xFF40C4FF),
          child: const Icon(Icons.center_focus_strong),
        ),
      ),
    );
  }
}

