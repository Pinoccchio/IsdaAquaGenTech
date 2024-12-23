import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Location data
  Region? _selectedRegion;
  Province? _selectedProvince;
  Municipality? _selectedMunicipality;
  String? _selectedBarangay;
  int? _selectedNumberOfCages;

  // Fish types
  final List<String> _fishTypes = ['TILAPIA', 'SHRIMPS'];
  List<String?> _selectedFishTypes = [];

  // Sample data for number of cages
  final List<int> _numberOfCagesOptions = List.generate(20, (index) => index + 1);

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Initialize FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String farmName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'farm_registration_channel',
      'Farm Registration Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Farm Registered: $farmName',
      'Your farm has been successfully registered.',
      platformChannelSpecifics,
    );
  }

  Future<void> _addAdminNotification(String farmName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('USERS')
            .doc(currentUser.uid)
            .collection('admin_notifications')
            .add({
          'message': 'New farm registered: $farmName',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      print('Error adding admin notification: $e');
    }
  }

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_pondImage == null) {
        _showErrorDialog('Please select a pond image');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('pond_images/${DateTime.now().toIso8601String()}.jpg');
        await storageRef.putFile(_pondImage!);
        final imageUrl = await storageRef.getDownloadURL();

        // Prepare fish types data
        List<Map<String, dynamic>> fishTypesData = [];
        for (int i = 0; i < _selectedFishTypes.length; i++) {
          fishTypesData.add({
            'cageNumber': i + 1,
            'fishType': _selectedFishTypes[i],
          });
        }

        // Save data to Firestore
        DocumentReference farmRef = await FirebaseFirestore.instance.collection('farms').add({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'farmName': _farmNameController.text,
          'numberOfCages': _selectedNumberOfCages,
          'fishTypes': fishTypesData,
          'address': _addressController.text,
          'region': _selectedRegion?.regionName,
          'province': _selectedProvince?.name,
          'municipality': _selectedMunicipality?.name,
          'barangay': _selectedBarangay,
          'contactNumber': _contactNumberController.text,
          'feedTypes': _feedTypesController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'pondImageUrl': imageUrl,
          'createdAt': DateFormat('h:mm a').format(DateTime.now()),
          'status': 'offline',
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Farm registered successfully')),
        );

        // Show local notification (Android only)
        await _showNotification(_farmNameController.text);

        // Add admin notification to Firestore
        await _addAdminNotification(_farmNameController.text);

        Navigator.of(context).pop(); // Return to previous screen after successful registration

      } catch (e) {
        _showErrorDialog('Error registering farm: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _farmNameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _feedTypesController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _lastNameController,
                        label: 'LAST NAME',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _farmNameController,
                  label: 'FARM NAME',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the farm name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedNumberOfCages,
                  items: _numberOfCagesOptions,
                  hint: 'NUMBER OF CAGES',
                  onChanged: (value) {
                    setState(() {
                      _selectedNumberOfCages = value;
                      _selectedFishTypes = List.filled(value ?? 0, null);
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select the number of cages';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedNumberOfCages != null)
                  ...List.generate(_selectedNumberOfCages!, (index) {
                    return Column(
                      children: [
                        _buildDropdown(
                          value: _selectedFishTypes[index],
                          items: _fishTypes,
                          hint: 'FISH TYPE FOR CAGE ${index + 1}',
                          onChanged: (value) {
                            setState(() {
                              _selectedFishTypes[index] = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a fish type for cage ${index + 1}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your complete address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _contactNumberController,
                  label: 'CONTACT NUMBER',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _feedTypesController,
                  label: 'FEED TYPES',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the feed types';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _usernameController,
                  label: 'USERNAME',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (!value.contains('fisher')) {
                      return 'Username must contain "fisher"';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  obscureText: !_isPasswordVisible,
                  isPasswordField: true,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'RE-TYPE PASSWORD',
                  obscureText: !_isConfirmPasswordVisible,
                  isPasswordField: true,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please re-type your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40C4FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'CREATE',
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
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
    bool isPasswordField = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscureText,
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
          suffixIcon: isPasswordField
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF40C4FF),
            ),
            onPressed: onToggleVisibility,
          )
              : null,
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF40C4FF),
          width: 2,
        ),
      ),
      child: DropdownButtonFormField<T>(
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
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
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
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: validator,
      ),
    );
  }
}