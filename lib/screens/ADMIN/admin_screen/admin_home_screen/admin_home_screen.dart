import 'package:flutter/material.dart';

class FarmData {
  final String name;
  final String imageUrl;
  final bool isActive;

  FarmData({
    required this.name,
    required this.imageUrl,
    required this.isActive,
  });
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

  // Dummy data for farms
  final List<FarmData> farms = [
    FarmData(
      name: 'FARM AAA',
      imageUrl: 'lib/assets/images/primary-logo.png',
      isActive: true,
    ),
    FarmData(
      name: 'FARM BBB',
      imageUrl: 'lib/assets/images/primary-logo.png',
      isActive: false,
    ),
    FarmData(
      name: 'FARM CCC',
      imageUrl: 'lib/assets/images/primary-logo.png',
      isActive: true,
    ),
    FarmData(
      name: 'FARM DDD',
      imageUrl: 'lib/assets/images/primary-logo.png',
      isActive: true,
    ),
    FarmData(
      name: 'FARM EEE',
      imageUrl: 'lib/assets/images/primary-logo.png',
      isActive: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Handle notifications
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: farms.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF40C4FF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          child: Image.asset(
                            farms[index].imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              farms[index].name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }
}

