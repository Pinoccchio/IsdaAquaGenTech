import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import '../../fish_scanner/fish_scanner.dart';
import '../../fisher_message_screen/fisher_message_screen.dart';

class FisherHomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  final String farmId;

  const FisherHomeScreen({
    Key? key,
    required this.openDrawer,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FisherHomeScreen> createState() => _FisherHomeScreenState();
}

class _FisherHomeScreenState extends State<FisherHomeScreen> {
  final String apiKey = 'de027726bde1251b15e2fb337b826f13';
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>>? forecast;
  Position? currentPosition;
  bool isLoading = true;
  String? cityName;
  String? farmName;
  DateTime currentTime = DateTime.now();
  Timer? timer;
  Timer? weatherTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchFarmData();
    _startClock();
    _startWeatherRefresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    weatherTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  void _startWeatherRefresh() {
    weatherTimer = Timer.periodic(const Duration(minutes: 5), (Timer t) {
      _getWeatherData();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });
      await _getLocationName();
      await _getWeatherData();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getLocationName() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=${currentPosition!.latitude}&lon=${currentPosition!.longitude}&limit=1&appid=$apiKey'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            cityName = '${data[0]['name']}, ${data[0]['state']}';
          });
        }
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
  }

  Future<void> _getWeatherData() async {
    if (currentPosition == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final currentWeatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${currentPosition!.latitude}&lon=${currentPosition!.longitude}&appid=$apiKey&units=metric'));

      final forecastResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${currentPosition!.latitude}&lon=${currentPosition!.longitude}&appid=$apiKey&units=metric'));

      if (currentWeatherResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        var currentWeatherData = json.decode(currentWeatherResponse.body);
        var forecastData = json.decode(forecastResponse.body);

        setState(() {
          weatherData = currentWeatherData;
        });

        List<Map<String, dynamic>> processedForecast = _processForecastData(forecastData);

        setState(() {
          forecast = processedForecast.take(4).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting weather data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _processForecastData(Map<String, dynamic> forecastData) {
    Map<String, List<dynamic>> dailyForecasts = {};
    for (var item in forecastData['list']) {
      String date = DateFormat('yyyy-MM-dd').format(
          DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));
      if (!dailyForecasts.containsKey(date)) {
        dailyForecasts[date] = [];
      }
      dailyForecasts[date]!.add(item);
    }

    List<Map<String, dynamic>> processedForecast = [];
    dailyForecasts.forEach((date, forecasts) {
      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      int rainCount = 0;
      String mainCondition = '';
      Map<String, int> conditionCounts = {};

      for (var forecast in forecasts) {
        double temp = forecast['main']['temp'].toDouble();
        minTemp = temp < minTemp ? temp : minTemp;
        maxTemp = temp > maxTemp ? temp : maxTemp;

        String condition = forecast['weather'][0]['main'];
        conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;

        if (condition == 'Rain' || condition == 'Thunderstorm') {
          rainCount++;
        }
      }

      mainCondition = conditionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      double probability = (rainCount / forecasts.length) * 100;

      processedForecast.add({
        'date': DateTime.parse(date),
        'minTemp': minTemp.round(),
        'maxTemp': maxTemp.round(),
        'condition': mainCondition,
        'probability': probability.round(),
      });
    });

    return processedForecast;
  }

  Future<void> _fetchFarmData() async {
    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .get();

      if (farmDoc.exists) {
        Map<String, dynamic> data = farmDoc.data() as Map<String, dynamic>;
        setState(() {
          farmName = data['farmName'] ?? 'Farm';
        });
      }
    } catch (e) {
      print('Error fetching farm data: $e');
    }
  }

  Future<void> _showImageSourceDialog() async {
    ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt, size: 32),
                          onPressed: () => Navigator.pop(context, ImageSource.camera),
                          color: const Color(0xFF40C4FF),
                        ),
                        const SizedBox(height: 8),
                        const Text('Camera'),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library, size: 32),
                          onPressed: () => Navigator.pop(context, ImageSource.gallery),
                          color: const Color(0xFF40C4FF),
                        ),
                        const SizedBox(height: 8),
                        const Text('Gallery'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FishScanner(
              farmId: widget.farmId,
              initialImage: File(image.path),
            ),
          ),
        );
      }
    }
  }

  String _getWeatherAnimation(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'lib/assets/animations/sunny.json';
      case 'clouds':
        return 'lib/assets/animations/cloudy.json';
      case 'rain':
        return 'lib/assets/animations/heavy-rain.json';
      case 'thunderstorm':
        return 'lib/assets/animations/lightning.json';
      default:
        return 'lib/assets/animations/sunny.json';
    }
  }

  String _getWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Sunny';
      case 'clouds':
        return 'Cloudy';
      case 'rain':
        return 'Heavy rain';
      case 'thunderstorm':
        return 'Lightning';
      default:
        return condition;
    }
  }

  Widget _buildCurrentWeather() {
    if (weatherData == null) return Container();

    final formattedDate = DateFormat('MMMM d, yyyy').format(currentTime);
    final formattedTime = DateFormat('h:mm:ss a').format(currentTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            '${weatherData!['main']['temp'].round()}°C',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          Text(
            weatherData!['weather'][0]['description'],
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherDetail(
                Icons.water_drop,
                'Humidity',
                '${weatherData!['main']['humidity']}%',
              ),
              _buildWeatherDetail(
                Icons.air,
                'Wind',
                '${weatherData!['wind']['speed']} m/s',
              ),
              _buildWeatherDetail(
                Icons.visibility,
                'Visibility',
                '${(weatherData!['visibility'] / 1000).toStringAsFixed(1)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.blue.shade700)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar (fixed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: widget.openDrawer,
                    color: Colors.black87,
                  ),
                  Image.asset(
                    'lib/assets/images/primary-logo.png',
                    height: 40,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FisherMessageScreen(farmId: widget.farmId),
                        ),
                      );
                    },
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        farmName != null ? farmName! : 'Loading...',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF40C4FF),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF40C4FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'NEWS & ANNOUNCEMENTS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                    (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCurrentWeather(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF40C4FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cityName ?? 'Loading location...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 20),
                                    onPressed: _getWeatherData,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else if (forecast != null)
                              Container(
                                height: 180,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    forecast!.length,
                                        (index) {
                                      final forecastData = forecast![index];
                                      return Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                DateFormat('EEE\nMMM d').format(forecastData['date']),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                height: 40,
                                                width: 40,
                                                child: Lottie.asset(
                                                  _getWeatherAnimation(forecastData['condition']),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getWeatherCondition(forecastData['condition']),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${forecastData['minTemp']}-${forecastData['maxTemp']} °C',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${forecastData['probability']}%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            _showImageSourceDialog();
          }
        },
        backgroundColor: const Color(0xFF40C4FF),
        child: const Icon(Icons.camera_alt, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

