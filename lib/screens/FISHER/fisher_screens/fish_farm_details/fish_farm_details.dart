import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class FishFarmDetails extends StatefulWidget {
  final String farmId;

  const FishFarmDetails({
    super.key,
    required this.farmId,
  });

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

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'FARM DETAILS': 'MGA DETALYE NG SAKAHAN',
      'FARM NAME': 'PANGALAN NG SAKAHAN',
      'OWNER': 'MAY-ARI',
      'CONTACT NUMBER': 'NUMERO NG CONTACT',
      'FEED TYPES': 'MGA URI NG PAGKAIN',
      'LOCATION': 'LOKASYON',
      'FISH TYPES': 'MGA URI NG ISDA',
      'No fish types registered': 'Walang nakarehistrong uri ng isda',
      'Add New Cage': 'Magdagdag ng Bagong Kulungan',
      'SUBMIT REQUEST': 'ISUMITE ANG KAHILINGAN',
      'REQUEST EDIT': 'HUMILING NG PAG-EDIT',
      'Edit request submitted successfully': 'Matagumpay na naisumite ang kahilingan sa pag-edit',
      'Error submitting edit request': 'Error sa pagsusumite ng kahilingan sa pag-edit',
      'This field is required': 'Kinakailangan ang patlang na ito',
      'Location not available': 'Hindi available ang lokasyon',
    },
    'Bisaya': {
      'FARM DETAILS': 'MGA DETALYE SA UMAHAN',
      'FARM NAME': 'NGALAN SA UMAHAN',
      'OWNER': 'TAG-IYA',
      'CONTACT NUMBER': 'NUMERO SA KONTAK',
      'FEED TYPES': 'MGA MATANG SA PAGKAON',
      'LOCATION': 'LOKASYON',
      'FISH TYPES': 'MGA MATANG SA ISDA',
      'No fish types registered': 'Walay nakalista nga mga matang sa isda',
      'Add New Cage': 'Pagdugang og Bag-ong Tangkal',
      'SUBMIT REQUEST': 'ISUMITE ANG HANGYO',
      'REQUEST EDIT': 'HANGYO OG PAG-USAB',
      'Edit request submitted successfully': 'Malampuson nga naisumite ang hangyo sa pag-usab',
      'Error submitting edit request': 'Sayup sa pagsumite sa hangyo sa pag-usab',
      'This field is required': 'Kinahanglan kini nga field',
      'Location not available': 'Dili magamit ang lokasyon',
    },
  };

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    _ownerController = TextEditingController();
    _contactNumberController = TextEditingController();
    _feedTypesController = TextEditingController();
    _locationController = TextEditingController();
    _loadFarmData();
    _initializeNotifications();
    _loadLanguagePreference();
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

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String farmName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'farm_registration_channel',
      'Farm Registration Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Edit Request Submitted',
      'Your edit request for $farmName has been submitted successfully.',
      platformChannelSpecifics,
    );
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
      // Split the owner name into firstName and lastName
      List<String> nameParts = _ownerController.text.split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Add to edit_requests collection
      DocumentReference editRequestRef = await FirebaseFirestore.instance
          .collection('edit_requests')
          .add({
        'farmId': widget.farmId,
        'requestedChanges': {
          'farmName': _farmNameController.text,
          'firstName': firstName,
          'lastName': lastName,
          'contactNumber': _contactNumberController.text,
          'feedTypes': _feedTypesController.text,
          'location': _locationController.text,
          'fishTypes': _fishTypes,
        },
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'isNewForAdmin': true,
        'isNew': true,
      });

      // Add to messages collection
      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'farmId': widget.farmId,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'fisher',
        'replyMessage': 'Edit request submitted for ${_farmNameController.text}',
        'isNew': true,
        'isNewForAdmin': true,
        'isVirusLikelyDetected': false,
        'requestedChanges': {
          'farmName': _farmNameController.text,
          'firstName': firstName,
          'lastName': lastName,
          'contactNumber': _contactNumberController.text,
          'feedTypes': _feedTypesController.text,
          'location': _locationController.text,
          'fishTypes': _fishTypes,
        },
        'status': 'pending',
        'editRequestId': editRequestRef.id,
      });

      await _showNotification(_farmNameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('Edit request submitted successfully')),
            backgroundColor: Colors.green, // Green for success
          ),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      print('Error submitting edit request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('Error submitting edit request')),
            backgroundColor: Colors.red, // Red for error
          ),
        );
      }
    }
  }

  Widget _buildInfoField(String label, TextEditingController controller, {bool enabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _getTranslatedText(label),
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
                return _getTranslatedText('This field is required');
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _updateFishType(int index, List<String> newFishTypes) {
    setState(() {
      _fishTypes[index]['fishTypes'] = newFishTypes;
    });
  }

  void _addNewFishType() {
    setState(() {
      _fishTypes.add({
        'cageNumber': _fishTypes.length + 1,
        'fishTypes': [_availableFishTypes[0]],
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
        Text(
          _getTranslatedText('FISH TYPES'),
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
          child: Column(
            children: [
              if (_fishTypes.isEmpty && !_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _getTranslatedText('No fish types registered'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ...List.generate(_fishTypes.length, (index) {
                final fishType = _fishTypes[index];
                final List<String> selectedTypes = List<String>.from(fishType['fishTypes'] ?? []);
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
                        Wrap(
                          spacing: 8,
                          children: _availableFishTypes.map((type) {
                            return FilterChip(
                              label: Text(type),
                              selected: selectedTypes.contains(type),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add(type);
                                  } else {
                                    selectedTypes.remove(type);
                                  }
                                  _updateFishType(index, selectedTypes);
                                });
                              },
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          selectedTypes.join(', '),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40C4FF),
                    ),
                    child: Text(
                      _getTranslatedText('Add New Cage'),
                      style: const TextStyle(color: Colors.white),
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
        Text(
          _getTranslatedText('LOCATION'),
          style: const TextStyle(
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
                : Center(child: Text(_getTranslatedText('Location not available'))),
          ),
        ),
        const SizedBox(height: 16),
      ],
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
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
                Text(
                  _getTranslatedText('FARM DETAILS'),
                  style: const TextStyle(
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
                      ? GestureDetector(
                    onTap: () => _showFullScreenImage(context, _pondImageUrl!),
                    child: CachedNetworkImage(
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
                _buildMap(),
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
                      _getTranslatedText(_isEditing ? 'SUBMIT REQUEST' : 'REQUEST EDIT'),
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

