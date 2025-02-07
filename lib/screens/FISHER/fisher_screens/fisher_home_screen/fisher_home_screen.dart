import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:flutter_news_service/flutter_news_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../fish_scanner/fish_scanner.dart';
import '../../fisher_message_screen/fisher_message_screen.dart';

class FisherHomeScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  final String farmId;
  final String selectedLanguage;

  const FisherHomeScreen({
    super.key,
    required this.openDrawer,
    required this.farmId,
    required this.selectedLanguage,
  });

  @override
  State<FisherHomeScreen> createState() => _FisherHomeScreenState();
}

class _FisherHomeScreenState extends State<FisherHomeScreen> {
  final String apiKey = 'de027726bde1251b15e2fb337b826f13';
  final FlutterNewsService newsService = FlutterNewsService('6745d27895264a84af01fd5f5cf1bc09');
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>>? forecast;
  Position? currentPosition;
  bool isLoading = true;
  String? cityName;
  String? farmName;
  DateTime currentTime = DateTime.now();
  Timer? timer;
  Timer? weatherTimer;
  final ScrollController _scrollController = ScrollController();
  List<Article> _news = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreNews = true;
  bool _hasNewReports = false;
  bool _hasNewMessages = false;
  bool _hasNewAlerts = false;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = false;
  int _currentAnnouncementIndex = 0; // Added variable

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchFarmData();
    _startClock();
    _startWeatherRefresh();
    _fetchNews();
    _listenForNewReportsAndAlerts();
    _listenForNewMessages();
    _fetchAnnouncements();
    Timer.periodic(const Duration(minutes: 15), (Timer t) => _refreshNews());
  }

  @override
  void dispose() {
    timer?.cancel();
    weatherTimer?.cancel();
    _scrollController.dispose();
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

  void _listenForNewReportsAndAlerts() {
    FirebaseFirestore.instance
        .collection('reports')
        .where('farmId', isEqualTo: widget.farmId)
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen((reportSnapshot) {
      FirebaseFirestore.instance
          .collection('alerts')
          .where('farmId', isEqualTo: widget.farmId)
          .where('isNew', isEqualTo: true)
          .snapshots()
          .listen((alertSnapshot) {
        if (mounted) {
          setState(() {
            _hasNewReports = reportSnapshot.docs.isNotEmpty;
            _hasNewAlerts = alertSnapshot.docs.isNotEmpty;
          });
        }
      });
    });
  }

  void _listenForNewMessages() {
    FirebaseFirestore.instance
        .collection('messages')
        .where('farmId', isEqualTo: widget.farmId)
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasNewMessages = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  void _navigateToMessageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FisherMessageScreen(farmId: widget.farmId),
      ),
    );
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
          forecast = processedForecast.take(5).toList();
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

  Widget _buildDetailedWeather() {
    if (weatherData == null) return Container();

    final sunrise = DateTime.fromMillisecondsSinceEpoch(weatherData!['sys']['sunrise'] * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(weatherData!['sys']['sunset'] * 1000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getTranslatedText('Weather Today in')} ${cityName ?? "your current location"}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('Feels Like'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${weatherData!['main']['feels_like'].round()}°',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40C4FF),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.wb_sunny_outlined, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 4),
                        Text(DateFormat('h:mm a').format(sunrise)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.nightlight_round, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 4),
                        Text(DateFormat('h:mm a').format(sunset)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildWeatherMetric('High/Low',
              '${weatherData!['main']['temp_max'].round()}°/${weatherData!['main']['temp_min'].round()}°'),
          _buildWeatherMetric('Wind', '${weatherData!['wind']['speed']} km/h'),
          _buildWeatherMetric('Humidity', '${weatherData!['main']['humidity']}%'),
          _buildWeatherMetric('Pressure', '${weatherData!['main']['pressure']} mb'),
          _buildWeatherMetric('Visibility', '${(weatherData!['visibility'] / 1000).toStringAsFixed(2)} km'),
          _buildWeatherMetric('Description', '${weatherData!['weather'][0]['description']}'),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTranslatedText(label),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchNews() async {
    if (_isLoadingMore || !_hasMoreNews) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final keywords = [
        /*
        'aquaculture',
        'fishing',
        'fish disease',
        'tilapia lake virus',
        'white spot syndrome virus',
        'fish farming',
        'seafood',
        'marine life',
        'ocean conservation',
        'fisheries',
        'aquatic ecosystems',
        'fish stock',
        'sustainable fishing',
        'fish market',
        'aquarium trade',
        'fish feed',
        'fish health',
        'fish breeding',
        'fish processing',
        'fish export',

         */
        //'fish'
      ];

      List<Article> newArticles = [];

      for (var keyword in keywords) {
        final result = await newsService.fetchEverything(
          q: keyword,
          sortBy: 'publishedAt',
          language: 'en',
          page: _currentPage,
          pageSize: 10,
        );
        newArticles.addAll(result.articles);
      }

      // Remove duplicates based on title and url
      newArticles = newArticles.fold<List<Article>>([], (List<Article> uniqueArticles, Article article) {
        if (!uniqueArticles.any((a) => a.title == article.title || a.url == article.url)) {
          uniqueArticles.add(article);
        }
        return uniqueArticles;
      });

      // Filter articles to ensure they are related to fishing and sea topics
      newArticles = newArticles.where((article) {
        final title = article.title.toLowerCase() ?? '';
        final description = article.description?.toLowerCase() ?? '';
        final content = article.content?.toLowerCase() ?? '';

        return keywords.any((keyword) =>
        title.contains(keyword) ||
            description.contains(keyword) ||
            content.contains(keyword));
      }).toList();

      // Sort by publishedAt
      newArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      setState(() {
        if (_currentPage == 1) {
          _news = newArticles;
        } else {
          _news.addAll(newArticles);
        }
        _currentPage++;
        _isLoadingMore = false;
        _hasMoreNews = newArticles.isNotEmpty;
      });
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _currentPage = 1;
      _hasMoreNews = true;
    });
    await _fetchNews();
  }

  Widget _buildNewsSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF40C4FF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getTranslatedText('FISHING & AQUACULTURE NEWS'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          Expanded(
            child: _news.isEmpty && _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _news.length + (_hasMoreNews ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _news.length) {
                  return _buildLoadMoreButton();
                }
                final article = _news[index];
                return GestureDetector(
                  onTap: () {
                    launchUrl(Uri.parse(article.url ?? ""));
                  },
                  child: Container(
                    width: 300,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 0,
                      right: 16,
                    ),
                    child: Card(
                      elevation: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article.urlToImage != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                child: CachedNetworkImage(
                                  imageUrl: article.urlToImage!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF40C4FF)),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    height: 150,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image not available',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  cacheManager: DefaultCacheManager(),
                                  maxHeightDiskCache: 1500,
                                  memCacheHeight: 1500,
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image available',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title ?? 'No title',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    article.description ?? 'No description available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Published: ${DateFormat('MMM d, yyyy').format(DateTime.parse(article.publishedAt))}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final Uri url = Uri.parse(article.url);
                                        if (!await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        )) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Could not open the article'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                                                        },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF40C4FF),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Read more',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoadingMore ? null : _fetchNews,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF40C4FF),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isLoadingMore
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            _getTranslatedText('Load\nMore'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherForecast() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
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
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _getWeatherData,
                  color: const Color(0xFF40C4FF),
                ),
              ],
            ),
          ),
          if (isLoading)
            const CircularProgressIndicator(color: Color(0xFF40C4FF))
          else if (forecast != null)
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: forecast!.length,
                itemBuilder: (context, index) {
                  final forecastData = forecast![index];
                  return Container(
                    width: 80,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('EEE\nMMM d').format(forecastData['date']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: Color(0xFF1565C0),
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
                          style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${forecastData['minTemp']}-${forecastData['maxTemp']} °C',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${forecastData['probability']}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchAnnouncements() async {
    if (_isLoadingAnnouncements) return;

    setState(() {
      _isLoadingAnnouncements = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _announcements = querySnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      print('Error fetching announcements: $e');
      setState(() {
        _isLoadingAnnouncements = false;
      });
    }
  }

  Widget _buildAnnouncementsSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF40C4FF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(
                      _getTranslatedText('ANNOUNCEMENTS'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingAnnouncements ? null : _fetchAnnouncements,
                  color: const Color(0xFF40C4FF),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingAnnouncements
                ? const Center(child: CircularProgressIndicator())
                : _announcements.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _getTranslatedText('No announcements yet'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : PageView.builder(
              itemCount: _announcements.length,
              onPageChanged: (index) {
                setState(() {
                  _currentAnnouncementIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                return AnnouncementCard(
                  announcement: announcement,
                  onTap: () {},
                );
              },
            ),
          ),
          if (_announcements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _announcements.length,
                      (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentAnnouncementIndex == index
                          ? const Color(0xFF40C4FF)
                          : const Color(0xFF40C4FF).withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTranslatedText(String key) {
    switch (widget.selectedLanguage) {
      case 'Filipino':
        return _filipinoTranslations[key] ?? key;
      case 'Bisaya':
        return _bisayaTranslations[key] ?? key;
      default:
        return key;
    }
  }

  final Map<String, String> _filipinoTranslations = {
    'FISHING & AQUACULTURE NEWS': 'BALITA SA PANGINGISDA AT AQUACULTURE',
    'Load\nMore': 'Magload\nPa',
    'ANNOUNCEMENTS': 'MGA ANUNSYO',
    'No announcements yet': 'Wala pang mga anunsyo',
    'Weather Today in': 'Panahon Ngayon sa',
    'Feels Like': 'Pakiramdam',
    'High/Low': 'Mataas/Mababa',
    'Wind': 'Hangin',
    'Humidity': 'Halumigmig',
    'Pressure': 'Presyon',
    'Visibility': 'Visibility',
    'Description': 'Paglalarawan',
  };

  final Map<String, String> _bisayaTranslations = {
    'FISHING & AQUACULTURE NEWS': 'BALITA SA PANGISDA UG AQUACULTURE',
    'Load\nMore': 'Pagload\nPa',
    'ANNOUNCEMENTS': 'MGA PAHIBALO',
    'No announcements yet': 'Wala pay mga pahibalo',
    'Weather Today in': 'Panahon Karon sa',
    'Feels Like': 'Gibati nga',
    'High/Low': 'Taas/Ubos',
    'Wind': 'Hangin',
    'Humidity': 'Kahumid',
    'Pressure': 'Presyon',
    'Visibility': 'Kakita',
    'Description': 'Paghulagway',
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                    showBadge: _hasNewReports || _hasNewAlerts,
                    badgeContent: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: widget.openDrawer,
                      color: Colors.black87,
                    ),
                  ),
                  Image.asset(
                    'lib/assets/images/primary-logo.png',
                    height: 40,
                  ),
                  badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                    showBadge: _hasNewMessages,
                    badgeContent: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: _navigateToMessageScreen,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNews,
                color: const Color(0xFF40C4FF),
                child: ListView(
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
                    _buildNewsSection(),
                    const SizedBox(height: 30),
                    _buildAnnouncementsSection(),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildDetailedWeather(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildWeatherForecast(),
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

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement['imageUrl'] != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, announcement['imageUrl']),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: announcement['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            if (announcement['text']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  announcement['text'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        );
      },
    );
  }
}
