import 'package:flutter/material.dart';
import 'package:isda_aqua_gentech/screens/fisherOrAdminLoginScreen/fisherOrAdminLoginScreen.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:isda_aqua_gentech/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/static_accounts/static_accounts.dart';
import '../ADMIN/admin_screen/admin_home_screen/admin_container_screen.dart';
import '../FISHER/fisher_screens/fisher_container_screen/fisher_container_screen.dart';
import '../FISHER/fisher_screens/fisher_home_screen/fisher_home_screen.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  bool isConnected = false;
  bool isInternetAccessible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
    });

    if (isConnected) {
      await _checkInternetAccess();
    } else {
      _showNoConnectionDialog();
    }
  }

  Future<void> _checkInternetAccess() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
      setState(() {
        isInternetAccessible = response.statusCode == 200;
      });

      if (isInternetAccessible) {
        await _initializeAdminAccount();
        _navigateToHome();
      } else {
        _showNoInternetAccessDialog();
      }
    } catch (e) {
      setState(() {
        isInternetAccessible = false;
      });
      _showNoInternetAccessDialog();
    }
  }

  Future<void> _initializeAdminAccount() async {
    await StaticAccounts.initializeAdminAccount();
  }

  Future<void> _navigateToHome() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('USERS').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['role'] == 'admin') {
        // User is an admin
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AdminHomeContainerScreen(),
          ),
        );
      } else {
        // User is a fisher
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FisherContainerScreen(),
          ),
        );
      }
    } else {
      // No user is signed in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FisherOrAdminLoginScreen(),
        ),
      );
    }
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('No Connection', style: TextStyle(color: AppColors.text)),
          content: Text('Please check your WiFi or cellular data connection.', style: TextStyle(color: AppColors.textLight)),
          actions: <Widget>[
            TextButton(
              child: Text('Retry', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectivity();
              },
            ),
          ],
        );
      },
    );
  }

  void _showNoInternetAccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('No Internet Access', style: TextStyle(color: AppColors.text)),
          content: Text('You are connected to a network, but there is no internet access.', style: TextStyle(color: AppColors.textLight)),
          actions: <Widget>[
            TextButton(
              child: Text('Retry', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectivity();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset(
                        'lib/assets/images/primary-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildConnectivityStatus(),
                  ],
                ),
                Positioned(
                  bottom: 50.0,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Lottie.asset(
                      'lib/assets/animations/dolphin-loading-screen.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectivityStatus() {
    IconData icon;
    String message;
    Color color;

    if (!isConnected) {
      icon = Icons.signal_wifi_off;
      message = 'No connection';
      color = AppColors.error;
    } else if (!isInternetAccessible) {
      icon = Icons.wifi_lock;
      message = 'No internet access';
      color = AppColors.error;
    } else {
      icon = Icons.wifi;
      message = 'Connected';
      color = AppColors.success;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}