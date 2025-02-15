import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'fisher-diary-detail-screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add-diary-entry-screen.dart'; // Import the new screen

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
  bool _isSelectedCageValid = false; // Added state variable

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
      'Once submitted, you cannot edit this information anymore.': 'Kapag nai-submit na, hindi mo na maaaring i-edit ang impormasyong ito.',
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
      'Once submitted, you cannot edit this information anymore.': 'Kung ma-submit na, dili na nimo mausab kini nga impormasyon.',
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
          List<Map<String, dynamic>> cageData = [];

          for (var cage in fishTypes) {
            if (cage['fishTypes'] != null) {
              List<dynamic> types = cage['fishTypes'] as List<dynamic>;
              cageData.add({
                'cageNumber': cage['cageNumber'],
                'organisms': types.map((type) => type.toString()).toList(),
              });
            }
          }

          setState(() {
            _cageData = cageData;
          });
        }
      }
    } catch (e) {
      print('Error loading farm data: $e');
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

  void _showAddEntryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDiaryEntryScreen(
          farmId: widget.farmId,
          cageData: _cageData,
        ),
      ),
    ).then((value) {
      if (value == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('Diary entry added successfully')),
            backgroundColor: _primaryColor,
          ),
        );
      }
    });
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
        onPressed: _showAddEntryScreen,
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

