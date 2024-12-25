import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';


class FishFarmDetails extends StatefulWidget {
  final String farmId;

  const FishFarmDetails({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FishFarmDetails> createState() => _FishFarmDetailsState();
}

class _FishFarmDetailsState extends State<FishFarmDetails> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _farmNameController;
  late TextEditingController _ownerController;
  late TextEditingController _contactNumberController;
  late TextEditingController _feedTypesController;
  late TextEditingController _locationController;
  String? _pondImageUrl;
  List<Map<String, dynamic>> _fishTypes = [];
  List<Map<String, dynamic>> _originalFishTypes = [];
  final List<String> _availableFishTypes = ['TILAPIA', 'SHRIMPS'];

  // New variables for map functionality
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _farmLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    _ownerController = TextEditingController();
    _contactNumberController = TextEditingController();
    _feedTypesController = TextEditingController();
    _locationController = TextEditingController();
    _loadFarmData();
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _ownerController.dispose();
    _contactNumberController.dispose();
    _feedTypesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmData() async {
    try {
      final DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        final data = farmDoc.data() as Map<String, dynamic>;
        setState(() {
          _farmNameController.text = data['farmName'] ?? '';
          _ownerController.text = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          _contactNumberController.text = data['contactNumber'] ?? '';
          _feedTypesController.text = data['feedTypes'] ?? '';
          _locationController.text = data['address'] ?? '';
          _pondImageUrl = data['pondImageUrl'];
          _fishTypes = List<Map<String, dynamic>>.from(data['fishTypes'] ?? []);
          _originalFishTypes = List<Map<String, dynamic>>.from(data['fishTypes'] ?? []);
        });
        await _updateLocation(data);
      }
    } catch (e) {
      print('Error loading farm data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading farm data')),
      );
    }
  }

  Future<void> _updateLocation(Map<String, dynamic> data) async {
    final GeoPoint? realtimeLocation = data['realtime_location'];
    if (realtimeLocation != null) {
      _farmLocation = LatLng(realtimeLocation.latitude, realtimeLocation.longitude);
    } else {
      final String address = data['address'] ?? '';
      if (address.isNotEmpty) {
        try {
          final location = Location();
          bool serviceEnabled;
          PermissionStatus permissionGranted;

          serviceEnabled = await location.serviceEnabled();
          if (!serviceEnabled) {
            serviceEnabled = await location.requestService();
            if (!serviceEnabled) {
              return;
            }
          }

          permissionGranted = await location.hasPermission();
          if (permissionGranted == PermissionStatus.denied) {
            permissionGranted = await location.requestPermission();
            if (permissionGranted != PermissionStatus.granted) {
              return;
            }
          }

          final LocationData locationData = await location.getLocation();
          _farmLocation = LatLng(locationData.latitude!, locationData.longitude!);

        } catch (e) {
          print('Error getting location from device: $e');
        }
      }
    }

    if (_farmLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId(widget.farmId),
            position: _farmLocation!,
            icon: data['status'] == 'online'
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
    }
  }


  Future<void> _requestEdit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('edit_requests')
          .add({
        'farmId': widget.farmId,
        'requestedChanges': {
          'farmName': _farmNameController.text,
          'owner': _ownerController.text,
          'contactNumber': _contactNumberController.text,
          'feedTypes': _feedTypesController.text,
          'location': _locationController.text,
          'fishTypes': _fishTypes, // Include fish types in the request
        },
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit request submitted successfully')),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      print('Error submitting edit request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting edit request')),
        );
      }
    }
  }

  Widget _buildInfoField(String label, TextEditingController controller, {bool enabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF40C4FF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateFishType(int index, String newFishType) {
    if (_availableFishTypes.contains(newFishType)) {
      setState(() {
        _fishTypes[index]['fishType'] = newFishType;
      });
    }
  }

  void _addNewFishType() {
    setState(() {
      _fishTypes.add({
        'cageNumber': _fishTypes.length + 1,
        'fishType': _availableFishTypes[0],
      });
    });
  }

  void _removeFishType(int index) {
    setState(() {
      _fishTypes.removeAt(index);
      // Update cage numbers
      for (int i = index; i < _fishTypes.length; i++) {
        _fishTypes[i]['cageNumber'] = i + 1;
      }
    });
  }

  Widget _buildFishTypesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FISH TYPES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF40C4FF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_fishTypes.isEmpty && !_isEditing)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No fish types registered',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ...List.generate(_fishTypes.length, (index) {
                final fishType = _fishTypes[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cage ${fishType['cageNumber']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (_isEditing)
                        DropdownButton<String>(
                          value: _availableFishTypes.contains(fishType['fishType'])
                              ? fishType['fishType']
                              : _availableFishTypes[0],
                          items: _availableFishTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _updateFishType(index, newValue);
                            }
                          },
                        )
                      else
                        Text(
                          fishType['fishType'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFishType(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _addNewFishType,
                    child: const Text(
                      'Add New Cage',
                      style: TextStyle(color: Colors.white), // Set text color to white
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40C4FF),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOCATION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF40C4FF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _farmLocation != null
                ? GoogleMap(
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
              },
            )
                : const Center(child: Text('Location not available')),
          ),
        ),
        const SizedBox(height: 16),
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
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _fishTypes = List<Map<String, dynamic>>.from(_originalFishTypes);
                  _loadFarmData();
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Farm Details Title
                const Text(
                  'FARM DETAILS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                // Farm Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pondImageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: _pondImageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'lib/assets/images/primary-logo.png',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Image.asset(
                    'lib/assets/images/primary-logo.png',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 24),

                // Farm Information Fields
                _buildInfoField('FARM NAME', _farmNameController, enabled: _isEditing),
                _buildInfoField('OWNER', _ownerController, enabled: _isEditing),
                _buildInfoField('CONTACT NUMBER', _contactNumberController, enabled: _isEditing),
                _buildInfoField('FEED TYPES', _feedTypesController, enabled: _isEditing),
                _buildInfoField('LOCATION', _locationController, enabled: _isEditing),
                _buildFishTypesList(),
                _buildMap(), // Add the map widget
                const SizedBox(height: 32),

                // Edit/Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isEditing) {
                        _requestEdit();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isEditing ? 'SUBMIT REQUEST' : 'REQUEST EDIT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

