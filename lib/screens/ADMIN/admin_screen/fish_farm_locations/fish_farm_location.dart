import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'fish_farm_details_screen.dart';

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

  Widget _buildReportsList() {
    if (_selectedFarmId == null) return const SizedBox.shrink();

    return Container(
      height: 250,
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
              _farmReports.isNotEmpty ? _farmReports[0]['farmName'] ?? 'Unknown Farm' : 'Select a Farm',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _farmReports.length,
              itemBuilder: (context, index) {
                final report = _farmReports[index];
                final detection = report['detection'] as String? ?? 'Unknown';
                final isVirusLikelyDetected = detection.toUpperCase().contains('LIKELY DETECTED') &&
                    !detection.toUpperCase().contains('NOT LIKELY DETECTED');

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FishFarmDetailsScreen(
                        reportId: report['id'],
                        farmData: report,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF40C4FF),
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                                : isVirusLikelyDetected
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _formatTimestamp(report['timestamp'] as Timestamp),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Text(
                            detection.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
        margin: const EdgeInsets.only(bottom: 266),
        child: FloatingActionButton(
          onPressed: _centerMapOnPhilippines,
          backgroundColor: const Color(0xFF40C4FF),
          child: const Icon(Icons.center_focus_strong),
        ),
      ),
    );
  }
}

