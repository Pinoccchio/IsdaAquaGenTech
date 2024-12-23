import 'package:flutter/material.dart';

class FishFarmDetails extends StatelessWidget {
  const FishFarmDetails({Key? key}) : super(key: key);

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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                child: Image.asset(
                  'lib/assets/images/primary-logo.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // Farm Information Fields
              _buildInfoSection('FARM NAME', 'FARM BBB'),
              _buildInfoSection('OWNER', 'JUAN DELA CRUZ'),
              _buildInfoSection('CONTACT NUMBER', '0906 221 1998'),
              _buildInfoSection('FEED TYPES', 'PELLETS'),
              _buildInfoSection('LOCATION', 'PANTAL, DAGUPAN, PANGASINAN'),

              const SizedBox(height: 32),

              // Request Edit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add edit functionality here
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
                  child: const Text(
                    'REQUEST EDIT',
                    style: TextStyle(
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
    );
  }

  Widget _buildInfoSection(String label, String value) {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF40C4FF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}