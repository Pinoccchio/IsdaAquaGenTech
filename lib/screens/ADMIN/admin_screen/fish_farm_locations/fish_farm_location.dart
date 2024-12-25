import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'farm_details_screen.dart';

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

  // Updated Philippines bounds definition
  static final LatLngBounds philippinesBounds = LatLngBounds(
    southwest: const LatLng(4.2259, 116.9282), // Southwest corner of Philippines
    northeast: const LatLng(21.3217, 126.6000), // Northeast corner of Philippines
  );

  @override
  void initState() {
    super.initState();
    _listenToFarmLocations();
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

  void _listenToFarmLocations() {
    FirebaseFirestore.instance.collection('farms').snapshots().listen((snapshot) {
      setState(() {
        _markers.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final GeoPoint? location = data['realtime_location'];
          if (location != null) {
            final marker = Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(location.latitude, location.longitude),
              icon: data['status'] == 'online'
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: data['farmName'] ?? 'Unnamed Farm',
                snippet: 'Tap to view details',
              ),
              onTap: () => _navigateToFarmDetails(doc.id),
            );
            _markers.add(marker);
          }
        }
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading farm locations: $error';
      });
    });
  }

  void _navigateToFarmDetails(String farmId) {
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmDetailScreen(farmId: farmId),
      ),
    );

     */
  }

  Future<void> _centerMapOnPhilippines() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      philippinesBounds,
      50.0, // padding
    ));
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);

    // Set map style to restrict to Philippines
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
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _centerMapOnPhilippines,
          backgroundColor: const Color(0xFF40C4FF),
          child: const Icon(Icons.center_focus_strong),
        ),
      ),
    );
  }
}

