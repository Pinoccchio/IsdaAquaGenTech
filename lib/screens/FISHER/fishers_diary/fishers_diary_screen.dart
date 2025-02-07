import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'fisher-diary-detail-screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FishersDiaryScreen extends StatefulWidget {
  final String farmId;

  const FishersDiaryScreen({Key? key, required this.farmId}) : super(key: key);

  @override
  _FishersDiaryScreenState createState() => _FishersDiaryScreenState();
}

class _FishersDiaryScreenState extends State<FishersDiaryScreen> {
  String _farmName = '';
  final TextEditingController _cageNoController = TextEditingController();
  String? _selectedOrganism;
  DateTime? _startDate;
  DateTime? _harvestDate;
  List<Map<String, dynamic>> _cageData = [];
  Set<String> _availableOrganisms = {};
  String _selectedLanguage = 'English';

  final Color _primaryColor = const Color(0xFF23B4BC);
  final Color _secondaryColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _borderColor = const Color(0xFF40C4FF);

  final Map<String, Map<String, String>> _translations = {
    'Filipino': {
      'Farmer\'s Diary': 'Talaarawan ng Magsasaka',
      'CAGE': 'CAGE',
      'ORGANISM': 'ORGANISMO',
      'START DATE': 'SIMULA',
      'HARVEST DATE': 'PAG-ANI',
      'NO DATA YET': 'WALA PANG DATOS',
      'Select Cage': 'Pumili ng Kulungan',
      'Select Organism': 'Pumili ng Organismo',
      'Select Date': 'Pumili ng Petsa',
      'SAVE': 'I-SAVE',
      'Delete Entry': 'Burahin ang Entry',
      'Are you sure you want to delete this diary entry?': 'Sigurado ka bang gusto mong burahin ang entry na ito?',
      'Cancel': 'Kanselahin',
      'Delete': 'Burahin',
      'Mark as Harvested': 'Markahan bilang Inani',
      'Are you sure you want to mark this entry as harvested?': 'Sigurado ka bang gusto mong markahan ang entry na ito bilang inani?',
      'Diary entry deleted successfully': 'Matagumpay na nabura ang entry sa talaarawan',
      'Diary entry marked as harvested': 'Namarkahan ang entry sa talaarawan bilang inani',
      'Diary entry added successfully': 'Matagumpay na naidagdag ang entry sa talaarawan',
      'Error saving diary entry': 'May error sa pag-save ng entry sa talaarawan',
    },
    'Bisaya': {
      'Farmer\'s Diary': 'Talaan sa Mag-uuma',
      'CAGE': 'CAGE',
      'ORGANISM': 'ORGANISMO',
      'START DATE': 'PAGSUGOD',
      'HARVEST DATE': 'PAG-ANI',
      'NO DATA YET': 'WALAY DATA PA',
      'Select Cage': 'Pilia ang Tangkal',
      'Select Organism': 'Pilia ang Organismo',
      'Select Date': 'Pilia ang Petsa',
      'SAVE': 'I-SAVE',
      'Delete Entry': 'Papasa ang Entry',
      'Are you sure you want to delete this diary entry?': 'Sigurado ka nga gusto nimo papason kini nga entry?',
      'Cancel': 'Kanselahon',
      'Delete': 'Papason',
      'Mark as Harvested': 'Markahi og Ani na',
      'Are you sure you want to mark this entry as harvested?': 'Sigurado ka nga gusto nimo markahan kini nga entry og ani na?',
      'Diary entry deleted successfully': 'Malampuson nga napapas ang entry sa talaan',
      'Diary entry marked as harvested': 'Namarkahan ang entry sa talaan og ani na',
      'Diary entry added successfully': 'Malampuson nga nadugang ang entry sa talaan',
      'Error saving diary entry': 'Naay sayop sa pag-save sa entry sa talaan',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadFarmData();
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

  Future<void> _loadFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        Map<String, dynamic> data = farmDoc.data() as Map<String, dynamic>;

        setState(() {
          _farmName = data['farmName'] ?? 'Farmer\'s Diary';
        });

        if (data['fishTypes'] != null) {
          List<dynamic> fishTypes = data['fishTypes'] as List<dynamic>;
          Set<String> organisms = {};

          for (var cage in fishTypes) {
            if (cage['fishTypes'] != null) {
              List<dynamic> types = cage['fishTypes'] as List<dynamic>;
              organisms.addAll(types.map((type) => type.toString()));
            }
          }

          setState(() {
            _cageData = List<Map<String, dynamic>>.from(fishTypes);
            _availableOrganisms = organisms;
          });
        }
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              _getTranslatedText('CAGE'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('ORGANISM'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('START DATE'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTranslatedText('HARVEST DATE'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _updateHarvestDate() {
    if (_startDate != null && _selectedOrganism != null) {
      setState(() {
        if (_selectedOrganism!.toUpperCase() == 'TILAPIA') {
          // For Tilapia: 6 months
          _harvestDate = DateTime(_startDate!.year, _startDate!.month + 6, _startDate!.day);
          // If the day is not the same, it means we've moved to the next month, so go back one day
          if (_harvestDate!.day != _startDate!.day) {
            _harvestDate = _harvestDate!.subtract(Duration(days: _harvestDate!.day));
          }
        } else if (_selectedOrganism!.toUpperCase() == 'SHRIMPS') {
          // For Shrimps: 4 months
          _harvestDate = DateTime(_startDate!.year, _startDate!.month + 4, _startDate!.day);
          // If the day is not the same, it means we've moved to the next month, so go back one day
          if (_harvestDate!.day != _startDate!.day) {
            _harvestDate = _harvestDate!.subtract(Duration(days: _harvestDate!.day));
          }
        }
      });
    }
  }

  List<String> _getOrganismsForCage(String cageNumber) {
    var cage = _cageData.firstWhere(
          (cage) => cage['cageNumber'].toString() == cageNumber,
      orElse: () => {'fishTypes': []},
    );
    return (cage['fishTypes'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  Future<void> _selectDate(BuildContext context, StateSetter setState) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: _secondaryColor,
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _startDate ?? DateTime.now(),
                onDateTimeChanged: (val) {
                  setState(() {
                    _startDate = val;
                    _updateHarvestDate();
                  });
                },
              ),
            ),
            CupertinoButton(
              child: Text('OK', style: TextStyle(color: _primaryColor)),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEntryDialog() async {
    _cageNoController.clear();
    _selectedOrganism = null;
    _startDate = null;
    _harvestDate = null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<String> availableOrganisms = _cageNoController.text.isNotEmpty
                ? _getOrganismsForCage(_cageNoController.text)
                : _availableOrganisms.toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    DropdownButtonFormField<String>(
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
                      items: _cageData.map((cage) {
                        return DropdownMenuItem<String>(
                          value: cage['cageNumber'].toString(),
                          child: Text('Cage ${cage['cageNumber']}'),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _cageNoController.text = value ?? '';
                          _selectedOrganism = null;
                        });
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedOrganism,
                        isExpanded: true,
                        underline: Container(),
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
                      ),
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
                      onTap: () => _selectDate(context, setState),
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
                        onPressed: () async {
                          if (_cageNoController.text.isNotEmpty &&
                              _selectedOrganism != null &&
                              _startDate != null &&
                              _harvestDate != null) {
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
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getTranslatedText('Diary entry added successfully')),
                                  backgroundColor: _primaryColor,
                                ),
                              );
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
                        },
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
          },
        );
      },
    );
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
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _getTranslatedText(_farmName),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTableHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('farms')
                    .doc(widget.farmId)
                    .collection('diary')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _primaryColor));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        _getTranslatedText('NO DATA YET'),
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor.withOpacity(0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FisherDiaryDetailScreen(
                                farmId: widget.farmId,
                                diaryId: doc.id,
                                startDate: (data['startDate'] as Timestamp).toDate(),
                                harvestDate: (data['harvestDate'] as Timestamp).toDate(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: _borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: data['isHarvested'] == true ? Colors.green[50] : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Cage ${data['cageNumber']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    data['organism'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat('MM/dd/yyyy').format((data['startDate'] as Timestamp).toDate()),
                                    style: const TextStyle(
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat('MM/dd/yyyy').format((data['harvestDate'] as Timestamp).toDate()),
                                    style: const TextStyle(
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: _textColor),
                                    itemBuilder: (context) => [
                                      if (data['isHarvested'] != true)
                                        PopupMenuItem(
                                          value: 'harvest',
                                          child: Text(_getTranslatedText('Mark as Harvested')),
                                        ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(_getTranslatedText('Delete')),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        // Show confirmation dialog
                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                              backgroundColor: Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(20),
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
                                                      _getTranslatedText('Delete Entry'),
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 15),
                                                    Text(
                                                      _getTranslatedText('Are you sure you want to delete this diary entry?'),
                                                      style: TextStyle(fontSize: 16),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    SizedBox(height: 20),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: <Widget>[
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(false),
                                                          child: Text(
                                                            _getTranslatedText('Cancel'),
                                                            style: TextStyle(color: Colors.grey[600]),
                                                          ),
                                                        ),
                                                        SizedBox(width: 20),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.of(context).pop(true),
                                                          child: Text(_getTranslatedText('Delete'), style: TextStyle(color: Colors.white)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(18.0),
                                                            ),
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

                                        if (shouldDelete == true) {
                                          await FirebaseFirestore.instance
                                              .collection('farms')
                                              .doc(widget.farmId)
                                              .collection('diary')
                                              .doc(doc.id)
                                              .delete();

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(_getTranslatedText('Diary entry deleted successfully')),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } else if (value == 'harvest') {
                                        // Show confirmation dialog for harvest
                                        final shouldHarvest = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                              backgroundColor: Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(20),
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
                                                      _getTranslatedText('Mark as Harvested'),
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 15),
                                                    Text(
                                                      _getTranslatedText('Are you sure you want to mark this entry as harvested?'),
                                                      style: TextStyle(fontSize: 16),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    SizedBox(height: 20),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: <Widget>[
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(false),
                                                          child: Text(
                                                            _getTranslatedText('Cancel'),
                                                            style: TextStyle(color: Colors.grey[600]),
                                                          ),
                                                        ),
                                                        SizedBox(width: 20),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.of(context).pop(true),
                                                          child: Text(_getTranslatedText('Mark as Harvested'), style: TextStyle(color: Colors.white)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: _primaryColor,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(18.0),
                                                            ),
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

                                        if (shouldHarvest == true) {
                                          await FirebaseFirestore.instance
                                              .collection('farms')
                                              .doc(widget.farmId)
                                              .collection('diary')
                                              .doc(doc.id)
                                              .update({'isHarvested': true});

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(_getTranslatedText('Diary entry marked as harvested')),
                                              backgroundColor: _primaryColor,
                                            ),
                                          );
                                        }
                                      }
                                    },
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}