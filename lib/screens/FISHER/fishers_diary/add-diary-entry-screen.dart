import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddDiaryEntryScreen extends StatefulWidget {
  final String farmId;
  final List<Map<String, dynamic>> cageData;

  const AddDiaryEntryScreen({
    Key? key,
    required this.farmId,
    required this.cageData,
  }) : super(key: key);

  @override
  _AddDiaryEntryScreenState createState() => _AddDiaryEntryScreenState();
}

class _AddDiaryEntryScreenState extends State<AddDiaryEntryScreen> {
  final TextEditingController _cageNoController = TextEditingController();
  String? _selectedOrganism;
  DateTime? _startDate;
  DateTime? _harvestDate;
  bool _isSelectedCageValid = false;
  String _selectedLanguage = 'English';

  final Color _primaryColor = const Color(0xFF23B4BC);
  final Color _secondaryColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _borderColor = const Color(0xFF40C4FF);

  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'Add Diary Entry': 'Magdagdag ng Entry sa Talaarawan',
      'CAGE': 'KULUNGAN',
      'ORGANISM': 'ORGANISMO',
      'START DATE': 'PETSA NG SIMULA',
      'HARVEST DATE': 'PETSA NG PAG-ANI',
      'Select Cage': 'Pumili ng Kulungan',
      'Select Organism': 'Pumili ng Organismo',
      'Select Date': 'Pumili ng Petsa',
      'SAVE': 'I-SAVE',
      'Select start date and organism first': 'Pumili muna ng petsa ng simula at organismo',
      'Diary entry added successfully': 'Matagumpay na naidagdag ang entry sa talaarawan',
      'Error saving diary entry': 'May error sa pag-save ng entry sa talaarawan',
      'Please fill in all fields': 'Mangyaring punan ang lahat ng fields',
    },
    'Bisaya': {
      'Add Diary Entry': 'Pagdugang og Entry sa Talaan',
      'CAGE': 'TANGKAL',
      'ORGANISM': 'ORGANISMO',
      'START DATE': 'PETSA SA PAGSUGOD',
      'HARVEST DATE': 'PETSA SA PAG-ANI',
      'Select Cage': 'Pagpili og Tangkal',
      'Select Organism': 'Pagpili og Organismo',
      'Select Date': 'Pagpili og Petsa',
      'SAVE': 'I-SAVE',
      'Select start date and organism first': 'Pagpili una og petsa sa pagsugod ug organismo',
      'Diary entry added successfully': 'Malampuson nga nadugang ang entry sa talaan',
      'Error saving diary entry': 'Naay sayop sa pag-save sa entry sa talaan',
      'Please fill in all fields': 'Palihug sulati ang tanang mga field',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  @override
  void dispose() {
    _cageNoController.dispose();
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

  void _updateHarvestDate() {
    if (_startDate != null && _selectedOrganism != null) {
      setState(() {
        if (_selectedOrganism!.toUpperCase() == 'TILAPIA') {
          _harvestDate = DateTime(_startDate!.year, _startDate!.month + 6, _startDate!.day);
        } else if (_selectedOrganism!.toUpperCase() == 'SHRIMPS') {
          _harvestDate = DateTime(_startDate!.year, _startDate!.month + 4, _startDate!.day);
        }
        if (_harvestDate!.day != _startDate!.day) {
          _harvestDate = _harvestDate!.subtract(Duration(days: _harvestDate!.day));
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _secondaryColor,
              onSurface: _textColor,
            ),
            dialogBackgroundColor: _secondaryColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _updateHarvestDate();
      });
    }
  }

  Future<List<String>> _getExistingDiaryEntriesForCage(String cageNumber) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('farms')
        .doc(widget.farmId)
        .collection('diary')
        .where('cageNumber', isEqualTo: int.parse(cageNumber))
        .get();

    return querySnapshot.docs.map((doc) => doc['organism'] as String).toList();
  }

  Future<void> _saveDiaryEntry() async {
    if (!_isSelectedCageValid ||
        _cageNoController.text.isEmpty ||
        _selectedOrganism == null ||
        _startDate == null ||
        _harvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('Please fill in all fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .collection('diary')
          .add({
        'cageNumber': int.parse(_cageNoController.text),
        'organism': _selectedOrganism,
        'startDate': _startDate,
        'harvestDate': _harvestDate,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('Error saving diary entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('Error saving diary entry')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        backgroundColor: _secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTranslatedText('Add Diary Entry'),
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedText('CAGE'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('farms')
                  .doc(widget.farmId)
                  .collection('diary')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<String> existingEntries = snapshot.data?.docs
                    .map((doc) => '${doc['cageNumber']}_${doc['organism']}')
                    .toList() ?? [];

                return DropdownButtonFormField<String>(
                  value: _cageNoController.text.isEmpty ? null : _cageNoController.text,
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text(_getTranslatedText('Select Cage'), style: TextStyle(color: _textColor.withOpacity(0.5))),
                  items: widget.cageData.map((cage) {
                    List<String> organisms = (cage['organisms'] as List<dynamic>?)?.cast<String>() ?? [];
                    int selectedOrganismsCount = organisms.where((org) => existingEntries.contains('${cage['cageNumber']}_$org')).length;
                    bool isDisabled = selectedOrganismsCount >= organisms.length;
                    return DropdownMenuItem<String>(
                      value: cage['cageNumber'].toString(),
                      enabled: !isDisabled,
                      child: Text(
                        'Cage ${cage['cageNumber']}',
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : _textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) async {
                    if (value != null) {
                      List<String> existingEntries = await _getExistingDiaryEntriesForCage(value);
                      setState(() {
                        _cageNoController.text = value;
                        _selectedOrganism = null;
                        _isSelectedCageValid = true;
                        var selectedCage = widget.cageData.firstWhere(
                              (cage) => cage['cageNumber'].toString() == value,
                          orElse: () => {'organisms': []},
                        );
                        List<String> availableOrganisms = (selectedCage['organisms'] as List<dynamic>?)?.cast<String>() ?? [];
                        availableOrganisms = availableOrganisms.where((organism) => !existingEntries.contains(organism)).toList();
                        if (availableOrganisms.length == 1) {
                          _selectedOrganism = availableOrganisms.first;
                        }
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('ORGANISM'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('farms')
                  .doc(widget.farmId)
                  .collection('diary')
                  .where('cageNumber', isEqualTo: int.tryParse(_cageNoController.text))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<String> existingEntries = snapshot.data?.docs
                    .map((doc) => doc['organism'] as String)
                    .toList() ?? [];

                var selectedCage = widget.cageData.firstWhere(
                      (cage) => cage['cageNumber'].toString() == _cageNoController.text,
                  orElse: () => {'organisms': []},
                );
                List<String> availableOrganisms = (selectedCage['organisms'] as List<dynamic>?)?.cast<String>() ?? [];
                availableOrganisms = availableOrganisms.where((organism) => !existingEntries.contains(organism)).toList();

                if (availableOrganisms.isEmpty) {
                  return SizedBox.shrink();
                }

                if (availableOrganisms.length == 1) {
                  _selectedOrganism = availableOrganisms.first;
                  return Text(
                    '${_getTranslatedText('ORGANISM')}: ${availableOrganisms.first}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedOrganism,
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text(_getTranslatedText('Select Organism'), style: TextStyle(color: _textColor.withOpacity(0.5))),
                  items: availableOrganisms.map((String organism) {
                    return DropdownMenuItem<String>(
                      value: organism,
                      child: Text(organism),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedOrganism = value;
                      _updateHarvestDate();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('START DATE'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startDate == null
                          ? _getTranslatedText('Select Date')
                          : DateFormat('MM/dd/yyyy').format(_startDate!),
                      style: TextStyle(
                        color: _startDate == null ? _textColor.withOpacity(0.5) : _textColor,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: _primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('HARVEST DATE'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _harvestDate == null
                        ? _getTranslatedText('Select start date and organism first')
                        : DateFormat('MM/dd/yyyy').format(_harvestDate!),
                    style: TextStyle(color: _harvestDate == null ? _textColor.withOpacity(0.5) : _textColor),
                  ),
                  if (_selectedOrganism != null)
                    Text(
                      '*${_selectedOrganism} = ${_selectedOrganism?.toUpperCase() == 'TILAPIA' ? '6' : '4'} months',
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDiaryEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

