import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import '../../fisher_reports_screen/fisher_reports_screen.dart';
import '../../tilapia_lake_virus_information_screen/tilapia_lake_virus_information_screen.dart';
import '../../whitespot_syndrome_virus_information_screen/whitespot_syndrome_virus_information_screen.dart';
import '../fish_farm_details/fish_farm_details.dart';
import '../fisher_home_screen/fisher_home_screen.dart';
import '../../../fisherOrAdminLoginScreen/fisherOrAdminLoginScreen.dart';

class FisherContainerScreen extends StatefulWidget {
  final String farmId;

  const FisherContainerScreen({Key? key, required this.farmId}) : super(key: key);

  @override
  _FisherContainerScreenState createState() => _FisherContainerScreenState();
}

class _FisherContainerScreenState extends State<FisherContainerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _farmName = 'FARM';
  String _firstName = '';
  String _lastName = '';
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Start location tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updateLocation(position);
    });
  }

  Future<void> _updateLocation(Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .update({
        'realtime_location': GeoPoint(position.latitude, position.longitude),
        'last_location_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _loadFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        Map<String, dynamic> data = farmDoc.data() as Map<String, dynamic>;
        setState(() {
          _farmName = data['farmName'] ?? 'FARM';
          _firstName = data['firstName'] ?? '';
          _lastName = data['lastName'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog.adaptive(
        title: const Text('Exit App', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit the app?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              exit(0);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF40C4FF),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'lib/assets/images/primary-logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _farmName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _buildMenuItem('REPORTS', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FisherReportsScreen(farmId: widget.farmId),
                        ),
                      );
                    }),
                    _buildMenuItem('FARM DETAILS', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FishFarmDetails(farmId: widget.farmId),
                        ),
                      );
                    }),
                    _buildMenuItem('TILAPIA LAKE VIRUS\nINFORMATION', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TilapiaLakeVirusInformationScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem('WHITE SPOT SYNDROME\nVIRUS INFORMATION', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WhiteSpotSyndromeVirusInformationScreen(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              _buildMenuItem(
                'LOG OUT',
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('farmId');
                  await prefs.remove('farmName');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const FisherOrAdminLoginScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                showDivider: false,
                icon: Icons.logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        body: FisherHomeScreen(
          openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          farmId: widget.farmId,
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {
    required VoidCallback onTap,
    bool showDivider = true,
    IconData? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
}