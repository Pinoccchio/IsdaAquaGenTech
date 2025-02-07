import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FisherDiaryDetailScreen extends StatefulWidget {
  final String farmId;
  final String diaryId;
  final DateTime startDate;
  final DateTime harvestDate;

  const FisherDiaryDetailScreen({
    Key? key,
    required this.farmId,
    required this.diaryId,
    required this.startDate,
    required this.harvestDate,
  }) : super(key: key);

  @override
  _FisherDiaryDetailScreenState createState() => _FisherDiaryDetailScreenState();
}

class _FisherDiaryDetailScreenState extends State<FisherDiaryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedWeek = 1;
  int _currentWeek = 1;
  final TextEditingController _bodyWeightController = TextEditingController();
  final TextEditingController _bodyLengthController = TextEditingController();
  final TextEditingController _survivalController = TextEditingController();
  final TextEditingController _waterTempController = TextEditingController();
  final TextEditingController _phLevelController = TextEditingController();
  final TextEditingController _salinityController = TextEditingController();
  final TextEditingController _dissolvedOxygenController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController();
  final TextEditingController _nitriteController = TextEditingController();
  final TextEditingController _ammoniaController = TextEditingController();

  final Color _primaryColor = const Color(0xFF23B4BC);
  final Color _borderColor = const Color(0xFF40C4FF);
  final Color _secondaryColor = Colors.white;
  final Color _textColor = Colors.black87;
  List<int> _allWeeks = [];

  @override
  void initState() {
    super.initState();
    _calculateWeeks();
    _loadWeekData();
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    _bodyLengthController.dispose();
    _survivalController.dispose();
    _waterTempController.dispose();
    _phLevelController.dispose();
    _salinityController.dispose();
    _dissolvedOxygenController.dispose();
    _turbidityController.dispose();
    _nitriteController.dispose();
    _ammoniaController.dispose();
    super.dispose();
  }

  void _calculateWeeks() {
    final now = DateTime.now();
    final difference = now.difference(widget.startDate).inDays;
    _currentWeek = max((difference / 7).ceil(), 1);
    final totalWeeks = widget.harvestDate.difference(widget.startDate).inDays ~/ 7;
    _allWeeks = List.generate(totalWeeks, (index) => index + 1);
    _selectedWeek = _currentWeek.clamp(1, totalWeeks);
  }

  bool _isWeekEditable(int week) {
    return week <= _currentWeek;
  }

  Future<void> _loadWeekData() async {
    try {
      final weekDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .collection('diary')
          .doc(widget.diaryId)
          .collection('weekly_data')
          .doc('week_$_selectedWeek')
          .get();

      if (weekDoc.exists) {
        final data = weekDoc.data() as Map<String, dynamic>;
        setState(() {
          _bodyWeightController.text = data['bodyWeight']?.toString() ?? '';
          _bodyLengthController.text = data['bodyLength']?.toString() ?? '';
          _survivalController.text = data['survival']?.toString() ?? '';
          _waterTempController.text = data['waterTemp']?.toString() ?? '';
          _phLevelController.text = data['phLevel']?.toString() ?? '';
          _salinityController.text = data['salinity']?.toString() ?? '';
          _dissolvedOxygenController.text = data['dissolvedOxygen']?.toString() ?? '';
          _turbidityController.text = data['turbidity']?.toString() ?? '';
          _nitriteController.text = data['nitrite']?.toString() ?? '';
          _ammoniaController.text = data['ammonia']?.toString() ?? '';
        });
      } else {
        _clearForm();
      }
    } catch (e) {
      print('Error loading week data: $e');
    }
  }

  void _clearForm() {
    _bodyWeightController.clear();
    _bodyLengthController.clear();
    _survivalController.clear();
    _waterTempController.clear();
    _phLevelController.clear();
    _salinityController.clear();
    _dissolvedOxygenController.clear();
    _turbidityController.clear();
    _nitriteController.clear();
    _ammoniaController.clear();
  }

  Future<void> _saveWeekData() async {
    if (!_isWeekEditable(_selectedWeek)) {
      Fluttertoast.showToast(
        msg: "Cannot save data for future weeks",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .collection('diary')
          .doc(widget.diaryId)
          .collection('weekly_data')
          .doc('week_$_selectedWeek')
          .set({
        'bodyWeight': double.tryParse(_bodyWeightController.text) ?? 0,
        'bodyLength': double.tryParse(_bodyLengthController.text) ?? 0,
        'survival': double.tryParse(_survivalController.text) ?? 0,
        'waterTemp': double.tryParse(_waterTempController.text) ?? 0,
        'phLevel': double.tryParse(_phLevelController.text) ?? 0,
        'salinity': double.tryParse(_salinityController.text) ?? 0,
        'dissolvedOxygen': double.tryParse(_dissolvedOxygenController.text) ?? 0,
        'turbidity': double.tryParse(_turbidityController.text) ?? 0,
        'nitrite': double.tryParse(_nitriteController.text) ?? 0,
        'ammonia': double.tryParse(_ammoniaController.text) ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
          msg: "Data saved successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving week data: $e');
      Fluttertoast.showToast(
          msg: "Error saving data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          enabled: _isWeekEditable(_selectedWeek),
          decoration: InputDecoration(
            suffixText: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor),
            ),
            filled: true,
            fillColor: _isWeekEditable(_selectedWeek) ? Colors.grey[50] : Colors.grey[200],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _secondaryColor,
        appBar: AppBar(
          backgroundColor: _secondaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _textColor),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Row(
            children: [
              DropdownButton<int>(
                value: _selectedWeek,
                items: _allWeeks.map((week) {
                  return DropdownMenuItem<int>(
                    value: week,
                    child: Text(
                      'WEEK $week',
                      style: TextStyle(
                        color: _isWeekEditable(week) ? _textColor : Colors.grey,
                        fontWeight: _isWeekEditable(week) ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeek = value;
                    });
                    _loadWeekData();
                  }
                },
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                underline: Container(),
              ),
              const SizedBox(width: 16),
              Text(
                DateFormat('MM/dd/yyyy').format(
                  widget.startDate.add(Duration(days: (_selectedWeek - 1) * 7)),
                ),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Week: $_currentWeek',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField('AVERAGE BODY WEIGHT:', _bodyWeightController),
                _buildInputField('AVERAGE BODY LENGTH:', _bodyLengthController),
                _buildInputField('% SURVIVAL:', _survivalController, suffix: '%'),
                _buildInputField('WATER TEMPERATURE (°C):', _waterTempController, suffix: '°C'),
                _buildInputField('pH LEVEL:', _phLevelController),
                _buildInputField('SALINITY (ppt):', _salinityController, suffix: 'ppt'),
                _buildInputField('DISSOLVED OXYGEN (ppm):', _dissolvedOxygenController, suffix: 'ppm'),
                _buildInputField('TURBIDITY (%):', _turbidityController, suffix: '%'),
                _buildInputField('NITRITE (ppm):', _nitriteController, suffix: 'ppm'),
                _buildInputField('AMMONIA (ppm):', _ammoniaController, suffix: 'ppm'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isWeekEditable(_selectedWeek) ? _saveWeekData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isWeekEditable(_selectedWeek) ? _primaryColor : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SAVE',
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
      ),
    );
  }
}

