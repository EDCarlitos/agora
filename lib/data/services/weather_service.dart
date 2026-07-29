import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // API gratuita Open-Meteo (Sin Tokens/Keys) - Coordenadas Cancún (UPQROO)
  static const String _weatherUrl =
      'https://api.open-meteo.com/v1/forecast?latitude=21.1619&longitude=-86.8515&current_weather=true';

  Future<WeatherData> getCurrentWeather() async {
    try {
      final response = await http
          .get(Uri.parse(_weatherUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];

        return WeatherData(
          temperature: (currentWeather['temperature'] as num).toDouble(),
          windSpeed: (currentWeather['windspeed'] as num).toDouble(),
          weatherCode: currentWeather['weathercode'] as int,
          isDay: (currentWeather['is_day'] as int) == 1,
        );
      }
    } catch (e) {
      // Fallback para garantizar siempre visualización inmediata
    }

    return WeatherData(
      temperature: 31.0,
      windSpeed: 12.5,
      weatherCode: 0,
      isDay: true,
      location: 'Cancún (UPQROO)',
    );
  }
}
