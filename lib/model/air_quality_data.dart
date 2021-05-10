import 'package:temperaturemonitor/air_quality_services.dart';

class AirQualityData {
  int airQualityIndex;
  String place;
  double latitude;
  double longitude;
  AirQualityLevel airQualityLevel;

  AirQualityData({
    this.airQualityIndex,
    this.place,
    this.latitude,
    this.longitude,
    this.airQualityLevel,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> airQualityJson) {
    return AirQualityData(
      airQualityIndex: airQualityJson['data']['aqi'],
      place: airQualityJson['data']['city']['name'],
      latitude: airQualityJson['data']['city']['geo'][0],
      longitude: airQualityJson['data']['city']['geo'][1],
      airQualityLevel: airQualityIndexToLevel(airQualityJson['data']['aqi']),
    );
  }
}
