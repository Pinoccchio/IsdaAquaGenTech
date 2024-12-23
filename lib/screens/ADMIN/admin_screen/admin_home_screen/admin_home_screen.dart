import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:isda_aqua_gentech/widgets/notification_badge.dart';
import 'dart:io';

import 'admin_notification_screen.dart';

class FarmData {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;

  FarmData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isActive,
  });

  factory FarmData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FarmData(
      id: doc.id,
      name: data['farmName'] ?? 'Unnamed Farm',
      imageUrl: data['pondImageUrl'] ?? 'lib/assets/images/placeholder.png',
      isActive: data['status'] == 'online',
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;

  const AdminHomeScreen({
    Key? key,
    required this.openDrawer,
  }) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
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
              exit(0); // This will exit the app
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: widget.openDrawer,
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
                  icon: const Icon(Icons.notifications_none, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()),
                    );
                  },
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: NotificationBadge(),
                ),
              ],
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
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
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
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: farms[index].isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

