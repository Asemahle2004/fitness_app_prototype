import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'running_distance_engine.dart';

class RunningWeatherConditions {
  final double temperatureC;
  final double humidityPercent;
  final double? apparentTemperatureC;
  final double? windKmh;
  final DateTime fetchedAt;
  final String source;

  const RunningWeatherConditions({
    required this.temperatureC,
    required this.humidityPercent,
    required this.apparentTemperatureC,
    required this.windKmh,
    required this.fetchedAt,
    this.source = 'Open-Meteo',
  });

  RunningWeatherAdjustment adjustmentFor(RunningGoalDistance goal) =>
      RunningDistanceEngine.weatherAdjustment(
        goal: goal,
        temperatureC: temperatureC,
        humidityPercent: humidityPercent,
      );
}

class RunningWeatherService {
  const RunningWeatherService();

  Future<RunningWeatherConditions?> currentForDevice() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return currentAt(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<RunningWeatherConditions?> currentAt({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      <String, String>{
        'latitude': latitude.toStringAsFixed(5),
        'longitude': longitude.toStringAsFixed(5),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'timezone': 'auto',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final current = decoded['current'];
    if (current is! Map) return null;

    double? number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    final temperature = number(current['temperature_2m']);
    final humidity = number(current['relative_humidity_2m']);
    if (temperature == null || humidity == null) return null;
    return RunningWeatherConditions(
      temperatureC: temperature,
      humidityPercent: humidity,
      apparentTemperatureC: number(current['apparent_temperature']),
      windKmh: number(current['wind_speed_10m']),
      fetchedAt: DateTime.now(),
    );
  }
}
