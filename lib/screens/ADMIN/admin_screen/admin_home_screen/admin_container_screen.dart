import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isda_aqua_gentech/screens/fisherOrAdminLoginScreen/fisherOrAdminLoginScreen.dart';
import '../admin_announcements_manager/admin_announcements_screen.dart';
// import '../admin_fisher_diary_screen/admin_fisher_diary_screen.dart';
import '../admin_reports_screen/admin_reports_screen.dart';
import '../fish_farm_locations/fish_farm_location.dart';
import '../regisiter_new_farm_screen/register_new_farm_screen.dart';
import './admin_home_screen.dart';

class AdminHomeContainerScreen extends StatefulWidget {
  const AdminHomeContainerScreen({super.key});

  @override
  _AdminHomeContainerScreenState createState() => _AdminHomeContainerScreenState();
}

class _AdminHomeContainerScreenState extends State<AdminHomeContainerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasNewReports = false;
  final bool _hasNewAlerts = false;

  @override
  void initState() {
    super.initState();
    _listenForNewReports();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const FisherOrAdminLoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('USERS').doc(user.uid).get();
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  void _listenForNewReports() {
    FirebaseFirestore.instance
        .collection('reports')
        .where('isNewForAdmin', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasNewReports = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          String userName = snapshot.data?['displayName'] ?? 'User';
          return Drawer(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF40C4FF),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 20.0),
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
                      const Text(
                        "ADMIN",
                        style: TextStyle(
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
                    children: [
                      _buildMenuItem('FISH FARM LOCATIONS', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FishFarmLocationScreen()),
                        );
                      }, showBadge: _hasNewReports),
                      _buildMenuItem('POST ANNOUNCEMENTS', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminAnnouncementsScreen()),
                        );
                      }),
                      _buildMenuItem('REPORTS', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
                        );
                      }, showBadge: _hasNewReports),
                      _buildMenuItem('REGISTER NEW FARM', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterNewFarmScreen()),
                        );
                      }),
                      //_buildMenuItem('FISHERMAN\'S DIARY', onTap: () {
                      //  Navigator.pop(context);
                      //  Navigator.push(
                      //    context,
                      //    MaterialPageRoute(builder: (context) => const AdminFishersDiaryScreen()),
                      //  );
                      //}),
                    ],
                  ),
                ),
                _buildMenuItem(
                  'LOG OUT',
                  onTap: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                  showDivider: false,
                  icon: Icons.logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      body: AdminHomeScreen(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  Widget _buildMenuItem(String title, {
    required VoidCallback onTap,
    bool showDivider = true,
    IconData? icon,
    bool showBadge = false,
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
              if (showBadge)
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

