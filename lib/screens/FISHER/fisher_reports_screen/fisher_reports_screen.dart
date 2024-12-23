import 'package:flutter/material.dart';

class FisherReportsScreen extends StatelessWidget {
  const FisherReportsScreen({Key? key}) : super(key: key);

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
            children: [
              const SizedBox(height: 24),

              // Reports Title
              const Text(
                'REPORTS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'REPORT ID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'DATE/TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'DETECTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Reports List
              _buildReportItem(
                'ID# 000003',
                '12/08/2024\n2:24 PM',
                'VIRUS LIKELY\nDETECTED',
                true,
              ),
              const SizedBox(height: 8),
              _buildReportItem(
                'ID# 000002',
                '12/03/2024\n1:40 PM',
                'VIRUS NOT\nLIKELY DETECTED',
                false,
              ),
              const SizedBox(height: 8),
              _buildReportItem(
                'ID# 000001',
                '11/20/2024\n9:52 AM',
                'VIRUS NOT\nLIKELY DETECTED',
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(String id, String dateTime, String detection, bool isDetected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateTime,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              detection,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDetected ? Colors.red : Colors.green,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}