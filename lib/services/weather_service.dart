// Location: agrivana\lib\services\weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Service for OpenWeatherMap API to get current weather by lat/lng.
class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>?> getCurrentWeather(
    double lat,
    double lng,
  ) async {
    try {
      final apiKey = ApiConfig.openWeatherMapKey;
      if (apiKey.isEmpty) return null;
      final uri = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$apiKey&units=metric&lang=id',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
