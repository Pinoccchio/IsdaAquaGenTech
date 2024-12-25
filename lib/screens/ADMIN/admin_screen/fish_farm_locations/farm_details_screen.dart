import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:geocoding/geocoding.dart';

class FarmDetailScreen extends StatefulWidget {
  final String farmId;

  const FarmDetailScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  _FarmDetailScreenState createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = true;
  Map<String, dynamic>? _farmData;
  Set<Marker> _markers = {};
  LatLng? _farmLocation;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (doc.exists) {
        setState(() {
          _farmData = doc.data();
          _isLoading = false;
        });
        await _updateLocation();
      }
    } catch (e) {
      print('Error loading farm data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    if (_farmData != null) {
      final GeoPoint? realtimeLocation = _farmData!['realtime_location'];
      if (realtimeLocation != null) {
        _farmLocation = LatLng(realtimeLocation.latitude, realtimeLocation.longitude);
      } else {
        // If realtime_location is not available, use the address to get coordinates
        final String address = _farmData!['address'] ?? '';
        if (address.isNotEmpty) {
          try {
            List<Location> locations = await locationFromAddress(address);
            if (locations.isNotEmpty) {
              _farmLocation = LatLng(locations.first.latitude, locations.first.longitude);
            }
          } catch (e) {
            print('Error getting location from address: $e');
          }
        }
      }

      if (_farmLocation != null) {
        setState(() {
          _markers = {
            Marker(
              markerId: MarkerId(widget.farmId),
              position: _farmLocation!,
              icon: _farmData!['status'] == 'online'
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };
        });
      }
    }
  }

  Widget _buildFishTypesList() {
    final List<dynamic> fishTypes = _farmData?['fishTypes'] ?? [];
    if (fishTypes.isEmpty) {
      return const Text('No fish types registered');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fishTypes.map<Widget>((fishType) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF40C4FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF40C4FF).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF40C4FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Text(
                  'Cage Number ${fishType['cageNumber']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water,
                      color: Color(0xFF40C4FF),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      fishType['fishType'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF40C4FF)),
        )),
      );
    }

    if (_farmData == null) {
      return const Scaffold(
        body: Center(child: Text('Farm not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF40C4FF),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: _farmData!['pondImageUrl'] ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF40C4FF)),
                  )),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Color(0xFF40C4FF)),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _farmData!['farmName'] ?? 'Unnamed Farm',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF40C4FF),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _farmData!['status'] == 'online'
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _farmData!['status'] == 'online' ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    'Owner Information',
                    [
                      'Name: ${_farmData!['firstName']} ${_farmData!['lastName']}',
                      'Contact: ${_farmData!['contactNumber']}',
                    ],
                    const Color(0xFF40C4FF),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    'Farm Information',
                    [
                      'Number of Cages: ${_farmData!['numberOfCages']}',
                      'Feed Types: ${_farmData!['feedTypes']}',
                      'Address: ${_farmData!['address']}',
                    ],
                    const Color(0xFF40C4FF),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    'Fish Types',
                    [],
                    const Color(0xFF40C4FF),
                    customContent: _buildFishTypesList(),
                  ),
                  const SizedBox(height: 24),
                  if (_farmLocation != null) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40C4FF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF40C4FF)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _farmLocation!,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: true,
                          myLocationButtonEnabled: false,
                          compassEnabled: true,
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                            Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items, Color color, {Widget? customContent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        if (customContent != null)
          customContent
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}