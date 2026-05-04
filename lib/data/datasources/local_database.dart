import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // A dictionary mapping common Sri Lankan cities to their coordinates
  // This allows Member 4 to demonstrate 'Dynamic Parameter Handling'
  final Map<String, Map<String, double>> _cityCoords = {
    'Colombo': {'lat': 6.9271, 'lon': 79.8612},
    'Kandy': {'lat': 7.2906, 'lon': 80.6337},
    'Galle': {'lat': 6.0367, 'lon': 80.2170},
    'Jaffna': {'lat': 9.6615, 'lon': 80.0068},
    'Negombo': {'lat': 7.2089, 'lon': 79.8351},
    'Matara': {'lat': 5.9549, 'lon': 80.5550},
    'Anuradhapura': {'lat': 8.3122, 'lon': 80.4131},
  };

  Future<String> getWeather(String locationName) async {
    try {
      // Default to Colombo coordinates if no match is found
      double lat = 6.9271;
      double lon = 79.8612;

      // Logic: Check if the event location string contains any of our known cities
      // e.g., if location is "BMICH, Colombo", it matches 'Colombo'
      for (var city in _cityCoords.keys) {
        if (locationName.toLowerCase().contains(city.toLowerCase())) {
          lat = _cityCoords[city]!['lat']!;
          lon = _cityCoords[city]!['lon']!;
          break;
        }
      }

      // Perform the REST API call with dynamic coordinates
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Ensure the data exists before accessing
        if (data.containsKey('current_weather')) {
          final temp = data['current_weather']['temperature'];
          // Open-Meteo returns double, we show as string
          return "$temp°C";
        }
        return "N/A";
      } else {
        // Log error status code for debugging if needed
        return "Error ${response.statusCode}";
      }
    } catch (e) {
      // Handle network errors (e.g., no internet)
      return "Offline";
    }
  }
}