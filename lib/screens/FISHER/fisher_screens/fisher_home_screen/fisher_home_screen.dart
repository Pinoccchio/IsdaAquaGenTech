import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class FisherHomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;

  const FisherHomeScreen({Key? key, required this.openDrawer}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

    try {
      final forecastResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${currentPosition!.latitude}&lon=${currentPosition!.longitude}&appid=$apiKey&units=metric'));

      if (forecastResponse.statusCode == 200) {
        var forecastData = json.decode(forecastResponse.body);

        // Group forecast by day
        Map<String, List<dynamic>> dailyForecasts = {};
        for (var item in forecastData['list']) {
          String date = DateFormat('yyyy-MM-dd').format(
              DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));
          if (!dailyForecasts.containsKey(date)) {
            dailyForecasts[date] = [];
          }
          dailyForecasts[date]!.add(item);
        }

        // Process daily forecasts
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

          // Get most common condition
          mainCondition = conditionCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          // Calculate rain probability
          double probability = (rainCount / forecasts.length) * 100;

          processedForecast.add({
            'date': DateTime.parse(date),
            'minTemp': minTemp.round(),
            'maxTemp': maxTemp.round(),
            'condition': mainCondition,
            'probability': probability.round(),
          });
        });

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
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
                  onPressed: () {},
                  color: Colors.black87,
                ),
              ],
            ),
          ),

          // News & Announcements
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

          // Weather Card
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

          const Spacer(),

          // Camera Button
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF40C4FF),
              child: const Icon(Icons.camera_alt, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}