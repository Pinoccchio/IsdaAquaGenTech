import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../admin_homescreen_fisher_report_screen/admin_homescreen_fisher_report_screen.dart';
import '../admin_message_screen/admin_message_screen.dart';
import '../fish_farm_locations/farm_details_screen.dart';
import 'admin_notification_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_auth/firebase_auth.dart';

class FarmData {
  final String id;
  final String name;
  final String imageUrl;
  final String status;
  final bool isActive;

  FarmData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.status,
    required this.isActive,
  });

  factory FarmData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FarmData(
      id: doc.id,
      name: data['farmName'] ?? 'Unnamed Farm',
      imageUrl: data['pondImageUrl'] ?? 'lib/assets/images/placeholder.png',
      status: data['status'] ?? 'pending',
      isActive: data['isActive'] ?? true,
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;

  const AdminHomeScreen({
    super.key,
    required this.openDrawer,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasNewReports = false;
  bool _hasNewEditRequests = false;
  bool _hasNewAdminNotifications = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _listenForNewReports();
    _listenForNewEditRequests();
    _listenForNewAdminNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _navigateToFarmDetails(String farmId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmDetailScreen(farmId: farmId),
      ),
    );
  }

  void _navigateToFarmReports(String farmId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminHomescreenFisherReportScreen(farmId: farmId),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'viruslikelydetected':
        return Colors.red;
      case 'virusnotlikelydetected':
        return Colors.green;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _navigateToAdminMessageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminMessageScreen()),
    );
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

  void _listenForNewEditRequests() {
    FirebaseFirestore.instance
        .collection('edit_requests')
        .where('isNewForAdmin', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasNewEditRequests = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  void _listenForNewAdminNotifications() {
    FirebaseFirestore.instance
        .collection('USERS')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('admin_notifications')
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasNewAdminNotifications = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  void _showFarmOptions(BuildContext context, FarmData farm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF40C4FF)),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToFarmDetails(farm.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Color(0xFF40C4FF)),
                title: const Text('View Reports'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToFarmReports(farm.id);
                },
              ),
              ListTile(
                leading: Icon(
                  farm.isActive ? Icons.block : Icons.check_circle,
                  color: const Color(0xFF40C4FF),
                ),
                title: Text(farm.isActive ? 'Deactivate Farm' : 'Reactivate Farm'),
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationDialog(
                    context,
                    farm.isActive ? 'Deactivate' : 'Reactivate',
                    farm.id,
                    !farm.isActive,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Farm'),
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationDialog(context, 'Delete', farm.id, null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, String action, String farmId, bool? newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm $action', style: const TextStyle(color: Color(0xFF40C4FF))),
          content: Text('Are you sure you want to $action this farm?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (action == 'Delete') {
                  _deleteFarm(farmId);
                } else {
                  _updateFarmStatus(farmId, newStatus!);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: action == 'Delete' ? Colors.red : const Color(0xFF40C4FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteFarm(String farmId) {
    FirebaseFirestore.instance.collection('farms').doc(farmId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Farm deleted successfully'),
        backgroundColor: Colors.green,
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete farm: $error'),
        backgroundColor: Colors.red,
      ));
    });
  }

  void _updateFarmStatus(String farmId, bool newStatus) {
    FirebaseFirestore.instance.collection('farms').doc(farmId).update({
      'isActive': newStatus
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus ? 'Farm activated successfully' : 'Farm deactivated successfully'),
        backgroundColor: Colors.green,
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update farm status: $error'),
        backgroundColor: Colors.red,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: badges.Badge(
            position: badges.BadgePosition.topEnd(top: 0, end: 3),
            showBadge: _hasNewReports,
            badgeContent: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: widget.openDrawer,
            ),
          ),
          title: Image.asset(
            'lib/assets/images/primary-logo.png',
            height: 40,
          ),
          centerTitle: true,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()),
                    );
                  },
                ),
                if (_hasNewEditRequests || _hasNewAdminNotifications)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where(Filter.or(
                  Filter('isNewForAdmin', isEqualTo: true),
                  Filter('isNewMessageFromAdmin', isEqualTo: true)
              ))
                  .where('source', whereIn: ['admin', 'fisher'])
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasNewMessages = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.black),
                      onPressed: _navigateToAdminMessageScreen,
                    ),
                    if (hasNewMessages)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF40C4FF),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'SEARCH FOR FISH FARM',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF40C4FF),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('farms').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<FarmData> farms = snapshot.data!.docs
                      .map((doc) => FarmData.fromFirestore(doc))
                      .where((farm) => farm.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

                  farms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                  if (farms.isEmpty) {
                    return const Center(child: Text('No farms found'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: farms.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _navigateToFarmReports(farms[index].id),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: farms[index].imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Image.asset(
                                          'lib/assets/images/primary-logo.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            farms[index].name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showFarmOptions(context, farms[index]),
                                          child: const Icon(Icons.more_vert, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: farms[index].isActive ? _getStatusColor(farms[index].status) : Colors.red,
                                  ),
                                ),
                              ),
                              if (!farms[index].isActive)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Inactive',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

