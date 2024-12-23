import 'package:flutter/material.dart';
import '../../fisher_reports_screen/fisher_reports_screen.dart';
import '../../tilapia_lake_virus_information_screen/tilapia_lake_virus_information_screen.dart';
import '../../whitespot_syndrome_virus_information_screen/whitespot_syndrome_virus_information_screen.dart';
import '../fish_farm_details/fish_farm_details.dart';
import '../fisher_home_screen/fisher_home_screen.dart';

class FisherContainerScreen extends StatefulWidget {
  const FisherContainerScreen({Key? key}) : super(key: key);

  @override
  _FisherContainerScreenState createState() => _FisherContainerScreenState();
}

class _FisherContainerScreenState extends State<FisherContainerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Text(
                    'FARM BBB',
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
                children: <Widget>[
                  const SizedBox(height: 20),
                  _buildMenuItem('REPORTS', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FisherReportsScreen(),
                      ),
                    );
                  }),
                  _buildMenuItem('FARM DETAILS', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FishFarmDetails(),
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
              onTap: () {
                Navigator.pop(context);
                // Add logout logic here
              },
              showDivider: false,
              icon: Icons.logout,
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
      body: FisherHomeScreen(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
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