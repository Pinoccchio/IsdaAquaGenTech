import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../fisher_reports_screen/fisher_reports_screen.dart';
import '../../fishers_diary/fishers_diary_screen.dart';
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
  String? _farmImageUrl;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  bool _hasNewReports = false;
  bool _hasNewAlerts = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadFarmData();
    _initializeLocationTracking();
    _checkForNewReportsAndAlerts();
    _loadLanguagePreference();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
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

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
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
          _farmImageUrl = data['pondImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  void _checkForNewReportsAndAlerts() {
    FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: widget.farmId)
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen((reportSnapshot) {
      FirebaseFirestore.instance
          .collection('alerts')
          .where('farmId', isEqualTo: widget.farmId)
          .where('isNew', isEqualTo: true)
          .snapshots()
          .listen((alertSnapshot) {
        if (mounted) {
          setState(() {
            _hasNewReports = reportSnapshot.docs.isNotEmpty;
            _hasNewAlerts = alertSnapshot.docs.isNotEmpty;
          });
        }
      });
    });
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Exit App', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit the app?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              exit(0);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  _saveLanguagePreference('English');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Filipino'),
                onTap: () {
                  _saveLanguagePreference('Filipino');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Bisaya'),
                onTap: () {
                  _saveLanguagePreference('Bisaya');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTranslatedText(String key) {
    final translations = {
      'Filipino': {
        'REPORTS': 'MGA ULAT',
        'FARM DETAILS': 'MGA DETALYE NG SAKAHAN',
        'TILAPIA LAKE VIRUS\nINFORMATION': 'IMPORMASYON SA\nTILAPIA LAKE VIRUS',
        'WHITE SPOT SYNDROME\nVIRUS INFORMATION': 'IMPORMASYON SA WHITE SPOT\nSYNDROME VIRUS',
        'LANGUAGE': 'WIKA',
        'LOG OUT': 'MAG-LOG OUT',
        'FARMER\'S DIARY': 'TALAARAWAN NG MAGSASAKA',
        'FARMER\'S LIBRARY': 'AKLATAN NG MAGSASAKA',
      },
      'Bisaya': {
        'REPORTS': 'MGA TAHO',
        'FARM DETAILS': 'MGA DETALYE SA UMAHAN',
        'TILAPIA LAKE VIRUS\nINFORMATION': 'IMPORMASYON SA\nTILAPIA LAKE VIRUS',
        'WHITE SPOT SYNDROME\nVIRUS INFORMATION': 'IMPORMASYON SA WHITE SPOT\nSYNDROME VIRUS',
        'LANGUAGE': 'PINULONGAN',
        'LOG OUT': 'PAG-LOG OUT',
        'FARMER\'S DIARY': 'DIARYOHAN SA MAG-UUMA',
        'FARMER\'S LIBRARY': 'LIBRARYA SA MAG-UUMA',
      },
    };

    if (_selectedLanguage == 'English') {
      return key;
    }
    return translations[_selectedLanguage]?[key] ?? key;
  }

  Future<void> _launchFarmersLibrary() async {
    final Uri url = Uri.parse('https://drive.google.com/drive/folders/1pN6Zao0ECBdZRg7sqPzpPprqpK-UsJk3?usp=drive_link');
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      // Show error dialog instead of throwing exception
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Could not open the Farmer\'s Library. Please check your internet connection and try again.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
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
                        child: _farmImageUrl != null
                            ? CachedNetworkImage(
                          imageUrl: _farmImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image.asset(
                            'lib/assets/images/primary-logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Image.asset(
                          'lib/assets/images/primary-logo.png',
                          width: 100,
                          height: 100,
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
                    _buildMenuItem(_getTranslatedText('REPORTS'), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FisherReportsScreen(
                            farmId: widget.farmId,
                            updateBadgeStatus: (bool hasNewReports) {
                              setState(() {
                                _hasNewReports = hasNewReports;
                              });
                            },
                          ),
                        ),
                      );
                    }, badge: _hasNewReports),
                    _buildMenuItem(_getTranslatedText('FARM DETAILS'), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FishFarmDetails(farmId: widget.farmId),
                        ),
                      );
                    }),
                    _buildMenuItem(_getTranslatedText('TILAPIA LAKE VIRUS\nINFORMATION'), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TilapiaLakeVirusInformationScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(_getTranslatedText('WHITE SPOT SYNDROME\nVIRUS INFORMATION'), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WhiteSpotSyndromeVirusInformationScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(_getTranslatedText('FARMER\'S DIARY'), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FishersDiaryScreen(farmId: widget.farmId),
                        ),
                      );
                    }),
                    _buildMenuItem(_getTranslatedText('FARMER\'S LIBRARY'), onTap: () {
                      Navigator.pop(context);
                      _launchFarmersLibrary();
                    }),
                    _buildMenuItem(_getTranslatedText('LANGUAGE'), onTap: _showLanguageSelectionDialog),
                  ],
                ),
              ),
              _buildMenuItem(
                _getTranslatedText('LOG OUT'),
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
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {
    required VoidCallback onTap,
    bool showDivider = true,
    IconData? icon,
    bool badge = false,
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (badge || (title == 'REPORTS' && (_hasNewReports || _hasNewAlerts)))
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
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

