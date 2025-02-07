import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FishFarmDetailsScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> farmData;

  const FishFarmDetailsScreen({
    Key? key,
    required this.reportId,
    required this.farmData,
  }) : super(key: key);

  @override
  _FishFarmDetailsScreenState createState() => _FishFarmDetailsScreenState();
}

class _FishFarmDetailsScreenState extends State<FishFarmDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _updateReportStatus();
  }

  Future<void> _updateReportStatus() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({'isNew': false});
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _extractOrganismName(String detection) {
    final parts = detection.split(' ');
    if (parts.length >= 2) {
      return parts[0];
    }
    return 'Unknown Organism';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final organismName = _extractOrganismName(widget.farmData['detection']);
    final bool isDiseaseDetected = !widget.farmData['detection'].toLowerCase().contains('not likely detected');

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
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'REPORT DETAILS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF40C4FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: widget.farmData['imageUrl'] != null && widget.farmData['imageUrl'].isNotEmpty
                          ? GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.farmData['imageUrl']),
                        child: CachedNetworkImage(
                          imageUrl: widget.farmData['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF40C4FF),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error),
                            ),
                          ),
                        ),
                      )
                          : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('No image available'),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF40C4FF)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF40C4FF)),
                            ),
                            child: Text(
                              organismName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF40C4FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ORGANISM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDiseaseDetected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDiseaseDetected ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    widget.farmData['detection'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDiseaseDetected ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', widget.farmData['farmName'] ?? ''),
              _buildTextField('OWNER', '${widget.farmData['ownerFirstName'] ?? ''} ${widget.farmData['ownerLastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', widget.farmData['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', widget.farmData['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', _formatTimestamp(widget.farmData['timestamp'])),
              _buildTextField('LOCATION', widget.farmData['locationDescription'] ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}

