import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationAlertDetailScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  final String alertId;

  const NotificationAlertDetailScreen({super.key, required this.alert, required this.alertId});

  @override
  _NotificationAlertDetailScreenState createState() => _NotificationAlertDetailScreenState();
}

class _NotificationAlertDetailScreenState extends State<NotificationAlertDetailScreen> {
  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'Alert Details': 'Mga Detalye ng Alerto',
      'ALERT': 'ALERTO',
      'No Image Available': 'Walang Magagamit na Larawan',
      'FARM NAME': 'PANGALAN NG SAKAHAN',
      'OWNER': 'MAY-ARI',
      'CONTACT NUMBER': 'NUMERO NG CONTACT',
      'FEED TYPES': 'MGA URI NG PAGKAIN',
      'DATE AND TIME REPORTED': 'PETSA AT ORAS NG PAG-ULAT',
      'LOCATION': 'LOKASYON',
      'FARM ID': 'ID NG SAKAHAN',
      'REPORT ID': 'ID NG ULAT',
      'STATUS': 'KATAYUAN',
      'REQUIRES IMMEDIATE ACTION': 'NANGANGAILANGAN NG AGARANG AKSYON',
      'Yes': 'Oo',
      'No': 'Hindi',
    },
    'Bisaya': {
      'Alert Details': 'Mga Detalye sa Alerto',
      'ALERT': 'ALERTO',
      'No Image Available': 'Walay Magamit nga Hulagway',
      'FARM NAME': 'NGALAN SA UMAHAN',
      'OWNER': 'TAG-IYA',
      'CONTACT NUMBER': 'NUMERO SA KONTAK',
      'FEED TYPES': 'MGA MATANG SA PAGKAON',
      'DATE AND TIME REPORTED': 'PETSA UG ORAS SA PAG-REPORT',
      'LOCATION': 'LOKASYON',
      'FARM ID': 'ID SA UMAHAN',
      'REPORT ID': 'ID SA REPORT',
      'STATUS': 'KAHIMTANG',
      'REQUIRES IMMEDIATE ACTION': 'NAGKINAHANGLAN OG DIHA-DIHA NGA AKSYON',
      'Yes': 'Oo',
      'No': 'Dili',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  String _getTranslatedText(String key) {
    if (_selectedLanguage == 'English') {
      return key;
    }
    return _translations[_selectedLanguage]?[key] ?? key;
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText(label),
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
    final timestamp = widget.alert['timestamp'] as Timestamp;
    final formattedTimestamp = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate());
    final requiresImmediateAction = widget.alert['requiresImmediateAction'] as bool;
    final detection = widget.alert['detection'] as String;
    final imageUrl = widget.alert['imageUrl'] as String?;

    // Mark the alert as not new when viewed
    FirebaseFirestore.instance
        .collection('alerts')
        .doc(widget.alertId)
        .update({'isNew': false});

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF40C4FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTranslatedText('Alert Details'),
          style: const TextStyle(color: Color(0xFF40C4FF), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _getTranslatedText('ALERT'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF40C4FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (imageUrl != null)
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, imageUrl),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF40C4FF)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF40C4FF)),
                  ),
                  child: Center(
                    child: Text(
                      _getTranslatedText('No Image Available'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: requiresImmediateAction
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: requiresImmediateAction ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    detection.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: requiresImmediateAction ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('FARM NAME', widget.alert['farmName'] ?? ''),
              _buildTextField('OWNER', '${widget.alert['ownerFirstName'] ?? ''} ${widget.alert['ownerLastName'] ?? ''}'),
              _buildTextField('CONTACT NUMBER', widget.alert['contactNumber'] ?? ''),
              _buildTextField('FEED TYPES', widget.alert['feedTypes'] ?? ''),
              _buildTextField('DATE AND TIME REPORTED', formattedTimestamp),
              _buildTextField('LOCATION', widget.alert['locationDescription'] ?? ''),
              _buildTextField('FARM ID', widget.alert['farmId'] ?? ''),
              _buildTextField('REPORT ID', widget.alert['reportId'] ?? ''),
              _buildTextField('STATUS', widget.alert['status'] ?? ''),
              _buildTextField('REQUIRES IMMEDIATE ACTION', requiresImmediateAction ? _getTranslatedText('Yes') : _getTranslatedText('No')),
            ],
          ),
        ),
      ),
    );
  }
}

