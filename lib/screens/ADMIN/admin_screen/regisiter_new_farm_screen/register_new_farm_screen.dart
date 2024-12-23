import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isda_aqua_gentech/screens/ADMIN/admin_screen/regisiter_new_farm_screen/src/constant/philippine_regions.dart';
import 'package:isda_aqua_gentech/screens/ADMIN/admin_screen/regisiter_new_farm_screen/src/model/municipality.dart';
import 'package:isda_aqua_gentech/screens/ADMIN/admin_screen/regisiter_new_farm_screen/src/model/province.dart';
import 'package:isda_aqua_gentech/screens/ADMIN/admin_screen/regisiter_new_farm_screen/src/model/region.dart';
import 'package:isda_aqua_gentech/screens/ADMIN/admin_screen/regisiter_new_farm_screen/src/widgets/philippine_region_dropdown_view.dart';
import 'dart:io';

class RegisterNewFarmScreen extends StatefulWidget {
  const RegisterNewFarmScreen({Key? key}) : super(key: key);

  @override
  State<RegisterNewFarmScreen> createState() => _RegisterNewFarmScreenState();
}

class _RegisterNewFarmScreenState extends State<RegisterNewFarmScreen> {
  File? _pondImage;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _feedTypesController = TextEditingController();

  // Location data
  Region? _selectedRegion;
  Province? _selectedProvince;
  Municipality? _selectedMunicipality;
  String? _selectedBarangay;
  String? _selectedNumberOfCages;

  // Sample data for number of cages
  final List<String> _numberOfCagesOptions = List.generate(20, (index) => (index + 1).toString());

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pondImage = File(image.path);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateAddress() {
    String address = '';
    if (_selectedBarangay != null) address += '$_selectedBarangay, ';
    if (_selectedMunicipality != null) address += '${_selectedMunicipality!.name}, ';
    if (_selectedProvince != null) address += '${_selectedProvince!.name}, ';
    if (_selectedRegion != null) address += _selectedRegion!.regionName;
    _addressController.text = address.trim();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _farmNameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _feedTypesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'REGISTRATION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF40C4FF), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _pondImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        _pondImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Center(
                      child: Text(
                        'ADD POND IMAGE',
                        style: TextStyle(
                          color: Color(0xFF40C4FF),
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _firstNameController,
                        label: 'FIRST NAME',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _lastNameController,
                        label: 'LAST NAME',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _farmNameController,
                  label: 'FARM NAME',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedNumberOfCages,
                  items: _numberOfCagesOptions,
                  hint: 'NUMBER OF CAGES',
                  onChanged: (value) {
                    setState(() {
                      _selectedNumberOfCages = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                PhilippineRegionDropdownView(
                  regions: philippineRegions,
                  value: _selectedRegion,
                  onChanged: (Region? value) {
                    setState(() {
                      _selectedRegion = value;
                      _selectedProvince = null;
                      _selectedMunicipality = null;
                      _selectedBarangay = null;
                      _updateAddress();
                    });
                  },
                ),
                const SizedBox(height: 16),
                PhilippineProvinceDropdownView(
                  provinces: _selectedRegion?.provinces ?? [],
                  value: _selectedProvince,
                  onChanged: (Province? value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedMunicipality = null;
                      _selectedBarangay = null;
                      _updateAddress();
                    });
                  },
                ),
                const SizedBox(height: 16),
                PhilippineMunicipalityDropdownView(
                  municipalities: _selectedProvince?.municipalities ?? [],
                  value: _selectedMunicipality,
                  onChanged: (Municipality? value) {
                    setState(() {
                      _selectedMunicipality = value;
                      _selectedBarangay = null;
                      _updateAddress();
                    });
                  },
                ),
                const SizedBox(height: 16),
                PhilippineBarangayDropdownView(
                  barangays: _selectedMunicipality?.barangays ?? [],
                  value: _selectedBarangay,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedBarangay = value;
                      _updateAddress();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _addressController,
                  label: 'ADDRESS',
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _contactNumberController,
                  label: 'CONTACT NUMBER',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _feedTypesController,
                  label: 'FEED TYPES',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle form submission
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40C4FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF40C4FF),
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

