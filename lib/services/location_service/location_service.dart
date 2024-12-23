import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static Future<List<String>> getRegions() async {
    // For demonstration purposes, we'll return a static list of regions
    return [
      'National Capital Region (NCR)',
      'Cordillera Administrative Region (CAR)',
      'Ilocos Region (Region I)',
      'Cagayan Valley (Region II)',
      'Central Luzon (Region III)',
      'CALABARZON (Region IV-A)',
      'MIMAROPA (Region IV-B)',
      'Bicol Region (Region V)',
      'Western Visayas (Region VI)',
      'Central Visayas (Region VII)',
      'Eastern Visayas (Region VIII)',
      'Zamboanga Peninsula (Region IX)',
      'Northern Mindanao (Region X)',
      'Davao Region (Region XI)',
      'SOCCSKSARGEN (Region XII)',
      'Caraga (Region XIII)',
      'Bangsamoro Autonomous Region in Muslim Mindanao (BARMM)'
    ];
  }

  static Future<List<String>> getProvinces(String region) async {
    // This is a simplified example. In a real application, you would fetch this data from an API or database.
    // For now, we'll return a static list of provinces for demonstration purposes.
    return [
      'Province 1',
      'Province 2',
      'Province 3',
      'Province 4',
      'Province 5',
    ];
  }

  static Future<List<String>> getCities(String province) async {
    // This is a simplified example. In a real application, you would fetch this data from an API or database.
    // For now, we'll return a static list of cities for demonstration purposes.
    return [
      'City 1',
      'City 2',
      'City 3',
      'City 4',
      'City 5',
    ];
  }

  static Future<List<String>> getBarangays(String city) async {
    // This is a simplified example. In a real application, you would fetch this data from an API or database.
    // For now, we'll return a static list of barangays for demonstration purposes.
    return [
      'Barangay 1',
      'Barangay 2',
      'Barangay 3',
      'Barangay 4',
      'Barangay 5',
    ];
  }
}