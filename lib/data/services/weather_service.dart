import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final String location;

  WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    this.location = 'Cancún (UPQROO)',
  });

  String get conditionText {
    switch (weatherCode) {
      case 0:
        return 'Despejado / Soleado';
      case 1:
      case 2:
      case 3:
        return 'Parcialmente Nublado';
      case 45:
      case 48:
        return 'Niebla';
      case 51:
      case 53:
      case 55:
        return 'Llovizna';
      case 61:
      case 63:
      case 65:
        return 'Lluvia';
      case 80:
      case 81:
      case 82:
        return 'Chubascos';
      case 95:
      case 96:
      case 99:
        return 'Tormenta Eléctrica';
      default:
        return 'Clima Caluroso';
    }
  }

  String get conditionIcon {
    switch (weatherCode) {
      case 0:
        return isDay ? '☀️' : '🌙';
      case 1:
      case 2:
      case 3:
        return '⛅';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
        return '🌧️';
      case 80:
      case 81:
      case 82:
        return '🌦️';
      case 95:
      case 96:
      case 99:
        return '🌩️';
      default:
        return '🌤️';
    }
  }
}

class WeatherService {
  // API gratuita Open-Meteo (Sin Tokens/Keys) - Coordenadas Cancún (UPQROO)
  static const String _weatherUrl =
      'https://api.open-meteo.com/v1/forecast?latitude=21.1619&longitude=-86.8515&current_weather=true';

  Future<WeatherData> getCurrentWeather() async {
    final response = await http
        .get(Uri.parse(_weatherUrl))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currentWeather = data['current_weather'];

      return WeatherData(
        temperature: (currentWeather['temperature'] as num).toDouble(),
        windSpeed: (currentWeather['windspeed'] as num).toDouble(),
        weatherCode: currentWeather['weathercode'] as int,
        isDay: (currentWeather['is_day'] as int) == 1,
      );
    } else {
      throw Exception('No se pudo obtener el clima.');
    }
  }
}
