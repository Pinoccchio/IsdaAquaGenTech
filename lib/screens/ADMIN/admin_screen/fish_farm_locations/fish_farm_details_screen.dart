import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  bool _isSendingAlert = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _selectedTime = TimeOfDay.now();

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _getFormattedDateTime() {
    final date = DateFormat('MMMM d, yyyy').format(_selectedDate);
    final time = _selectedTime.format(context);
    return '$date at $time';
  }

  Future<void> _showMessageAlert() async {
    final detection = widget.farmData['detection'] as String? ?? 'Unknown';
    final bool isVirusLikelyDetected = !detection.toLowerCase().contains('not likely detected');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'MESSAGE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NEEDED ACTION:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isVirusLikelyDetected
                                  ? 'A SCIENTIST WILL VISIT YOUR FARM TO COLLECT SAMPLES FOR CONFIRMATORY TEST.'
                                  : 'NO IMMEDIATE ACTION REQUIRED. CONTINUE MONITORING YOUR FARM AND REPORT ANY CHANGES IN FISH HEALTH.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isVirusLikelyDetected) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'SELECT VISITATION DATE AND TIME:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context).then((_) => setState(() {})),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MM/dd/yyyy').format(_selectedDate),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context).then((_) => setState(() {})),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedTime.format(context),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(Icons.access_time, color: Colors.blue, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Selected: ${_getFormattedDateTime()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _sendAlert(isVirusLikelyDetected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'SEND MESSAGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendAlert(bool isVirusLikelyDetected) async {
    if (_isSendingAlert) return;

    setState(() {
      _isSendingAlert = true;
    });

    try {
      final farmId = widget.farmData['farmId'];
      if (farmId == null) {
        throw Exception('Farm ID is null');
      }

      final detection = widget.farmData['detection'] as String? ?? 'Unknown';

      final String replyMessage = isVirusLikelyDetected
          ? 'A SCIENTIST WILL VISIT YOUR FARM TO COLLECT SAMPLES FOR CONFIRMATORY TEST.'
          : 'NO IMMEDIATE ACTION REQUIRED. CONTINUE MONITORING YOUR FARM AND REPORT ANY CHANGES IN FISH HEALTH.';

      // Save the alert in the alerts collection
      final alertRef = await FirebaseFirestore.instance
          .collection('alerts')
          .add({
        'reportId': widget.reportId,
        'farmName': widget.farmData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.farmData['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': widget.farmData['ownerLastName'] ?? 'Unknown',
        'detection': detection,
        'latitude': widget.farmData['location']?['latitude'],
        'longitude': widget.farmData['location']?['longitude'],
        'locationDescription': widget.farmData['locationDescription'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': isVirusLikelyDetected ? 'viruslikelydetected' : 'virusnotlikelydetected',
        'farmId': farmId,
        'requiresImmediateAction': isVirusLikelyDetected,
        'contactNumber': widget.farmData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.farmData['feedTypes'] ?? 'Unknown',
        'imageUrl': widget.farmData['imageUrl'] ?? '',
      });

      // Store the alert as a message
      await FirebaseFirestore.instance
          .collection('messages')
          .add({
        'alertId': alertRef.id,
        'farmId': farmId,
        'content': 'Alert: $detection at ${widget.farmData['farmName'] ?? 'Unknown Farm'}',
        'replyMessage': replyMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'type': 'alert',
        'isVirusLikelyDetected': isVirusLikelyDetected,
        'detection': detection,
        'farmName': widget.farmData['farmName'] ?? 'Unknown',
        'ownerFirstName': widget.farmData['ownerFirstName'] ?? 'Unknown',
        'ownerLastName': widget.farmData['ownerLastName'] ?? 'Unknown',
        'contactNumber': widget.farmData['contactNumber'] ?? 'Unknown',
        'feedTypes': widget.farmData['feedTypes'] ?? 'Unknown',
        'location': {
          'latitude': widget.farmData['location']?['latitude'],
          'longitude': widget.farmData['location']?['longitude'],
          'description': widget.farmData['locationDescription'],
        },
        'imageUrl': widget.farmData['imageUrl'] ?? '',
        'source': 'admin',
        'visitationDateTime': isVirusLikelyDetected ? _getFormattedDateTime() : null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent and message stored successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert and store message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final organismName = _extractOrganismName(widget.farmData['detection']);
    final bool isVirusLikelyDetected = !widget.farmData['detection'].toLowerCase().contains('not likely detected');

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
              Center(
                child: Text(
                  'REPORT',
                  style: const TextStyle(
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
                          ? Image.network(
                        widget.farmData['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      )
                          : const Center(
                        child: Text(
                          'No image available',
                          style: TextStyle(color: Colors.grey),
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
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isVirusLikelyDetected
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    widget.farmData['detection'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVirusLikelyDetected ? Colors.red : Colors.green,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showMessageAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40C4FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'VIEW MESSAGE ALERT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

