import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _selectedLanguage = 'English';
  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'WEEK': 'LINGGO',
      'Current Week': 'Kasalukuyang Linggo',
      'AVERAGE BODY WEIGHT': 'KARANIWANG TIMBANG',
      'AVERAGE BODY LENGTH': 'KARANIWANG HABA',
      '% SURVIVAL': '% NABUBUHAY',
      'WATER TEMPERATURE': 'TEMPERATURA NG TUBIG',
      'pH LEVEL': 'ANTAS NG pH',
      'SALINITY': 'ALAT',
      'DISSOLVED OXYGEN': 'NALUSAW NA OXYGEN',
      'TURBIDITY': 'KALABUAN',
      'NITRITE': 'NITRITE',
      'AMMONIA': 'AMMONYA',
      'SAVE': 'I-SAVE',
      'Data saved successfully': 'Matagumpay na na-save ang data',
      'Error saving data': 'May error sa pag-save ng data',
      'Cannot save data for future weeks': 'Hindi pwedeng i-save ang data para sa mga susunod na linggo',
      'Confirm Save': 'Kumpirmahin ang Pag-save',
      'Once submitted, this data cannot be edited. Are you sure you want to save?': 'Kapag nai-submit na, hindi na maaaring i-edit ang datos na ito. Sigurado ka bang gusto mong i-save?',
      'Cancel': 'Kanselahin',
      'Save': 'I-save',
      'Cannot Edit': 'Hindi Maaaring I-edit',
      'Once submitted, you cannot edit this information anymore.': 'Kapag nai-submit na, hindi mo na maaaring i-edit ang impormasyong ito.',
      'OK': 'OK',
    },
    'Bisaya': {
      'WEEK': 'SEMANA',
      'Current Week': 'Kasamtangang Semana',
      'AVERAGE BODY WEIGHT': 'AVERAGE NGA GIBUG-ATON',
      'AVERAGE BODY LENGTH': 'AVERAGE NGA GITAS-ON',
      '% SURVIVAL': '% NABUHI',
      'WATER TEMPERATURE': 'TEMPERATURA SA TUBIG',
      'pH LEVEL': 'LEBEL SA pH',
      'SALINITY': 'KAPARAT',
      'DISSOLVED OXYGEN': 'NATUNAW NGA OXYGEN',
      'TURBIDITY': 'KABULINGON',
      'NITRITE': 'NITRITE',
      'AMMONIA': 'AMMONYA',
      'SAVE': 'I-SAVE',
      'Data saved successfully': 'Malampuson nga na-save ang data',
      'Error saving data': 'Naay sayop sa pag-save sa data',
      'Cannot save data for future weeks': 'Dili pwede i-save ang data para sa umaabot nga mga semana',
      'Confirm Save': 'Kumpirmaha ang Pag-save',
      'Once submitted, this data cannot be edited. Are you sure you want to save?': 'Kung ma-submit na, dili na mahimong usbon kini nga datos. Sigurado ka ba nga gusto nimong i-save?',
      'Cancel': 'Kanselahon',
      'Save': 'I-save',
      'Cannot Edit': 'Dili Mausab',
      'Once submitted, you cannot edit this information anymore.': 'Kung ma-submit na, dili na nimo mausab kini nga impormasyon.',
      'OK': 'OK',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
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
        msg: _getTranslatedText("Cannot save data for future weeks"),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    bool shouldSave = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _getTranslatedText('Confirm Save'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _getTranslatedText('Once submitted, this data cannot be edited. Are you sure you want to save?'),
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        _getTranslatedText('Cancel'),
                        style: TextStyle(color: _textColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _getTranslatedText('Save'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!shouldSave) return;

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
          msg: _getTranslatedText("Data saved successfully"),
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
          msg: _getTranslatedText("Error saving data"),
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
    bool isEditable = _isWeekEditable(_selectedWeek) && controller.text.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText(label),
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
          enabled: isEditable,
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
            fillColor: isEditable ? Colors.white : Colors.grey[200],
          ),
          onTap: () {
            if (!isEditable) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: Offset(0.0, 10.0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _getTranslatedText('Cannot Edit'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _getTranslatedText('Once submitted, you cannot edit this information anymore.'),
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _getTranslatedText('OK'),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  bool _hasEditableFields() {
    return _bodyWeightController.text.isEmpty ||
        _bodyLengthController.text.isEmpty ||
        _survivalController.text.isEmpty ||
        _waterTempController.text.isEmpty ||
        _phLevelController.text.isEmpty ||
        _salinityController.text.isEmpty ||
        _dissolvedOxygenController.text.isEmpty ||
        _turbidityController.text.isEmpty ||
        _nitriteController.text.isEmpty ||
        _ammoniaController.text.isEmpty;
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
                      '${_getTranslatedText("WEEK")} $week',
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
                  '${_getTranslatedText("Current Week")}: $_currentWeek',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField('AVERAGE BODY WEIGHT', _bodyWeightController),
                _buildInputField('AVERAGE BODY LENGTH', _bodyLengthController),
                _buildInputField('% SURVIVAL', _survivalController, suffix: '%'),
                _buildInputField('WATER TEMPERATURE', _waterTempController, suffix: '°C'),
                _buildInputField('pH LEVEL', _phLevelController),
                _buildInputField('SALINITY', _salinityController, suffix: 'ppt'),
                _buildInputField('DISSOLVED OXYGEN', _dissolvedOxygenController, suffix: 'ppm'),
                _buildInputField('TURBIDITY', _turbidityController, suffix: '%'),
                _buildInputField('NITRITE', _nitriteController, suffix: 'ppm'),
                _buildInputField('AMMONIA', _ammoniaController, suffix: 'ppm'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isWeekEditable(_selectedWeek) && _hasEditableFields()
                      ? ElevatedButton(
                    onPressed: _saveWeekData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _getTranslatedText('SAVE'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

