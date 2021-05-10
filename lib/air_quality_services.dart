library air_quality;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:temperaturemonitor/model/air_quality_data.dart';

/// Custom Exception for the plugin,
/// Thrown whenever the API responds with an error and body could not be parsed.
class AirQualityAPIException implements Exception {
  String _cause;

  AirQualityAPIException(this._cause);

  String toString() => '${this.runtimeType} - $_cause';
}

enum AirQualityLevel {
UNKNOWN,
  GOOD,
  NORMAL,
  UNHEALTHY_FOR_SENSITIVE_GROUPS,
  UNHEALTHY,
  VERY_UNHEALTHY,
  HAZARDOUS
}

AirQualityLevel airQualityIndexToLevel(int index) {
  if (index < 0)
    return AirQualityLevel.UNKNOWN;
  else if (index <= 50)
    return AirQualityLevel.GOOD;
  else if (index <= 100)
    return AirQualityLevel.NORMAL;
  else if (index <= 150)
    return AirQualityLevel.UNHEALTHY_FOR_SENSITIVE_GROUPS;
  else if (index <= 200)
    return AirQualityLevel.UNHEALTHY;
  else if (index <= 300)
    return AirQualityLevel.VERY_UNHEALTHY;
  else
    return AirQualityLevel.HAZARDOUS;
}


class AirQuality {
  String _token;
  String _endpoint = 'https://api.waqi.info/feed/';

  AirQuality(this._token);

  /// Returns an [AirQualityData] object given a city name or a weather station ID
  Future<AirQualityData> feedFromCity(String city) async =>
      await _airQualityFromUrl(city);

  /// Returns an [AirQualityData] object given a city name or a weather station ID
  Future<AirQualityData> feedFromStationId(String stationId) async =>
      await _airQualityFromUrl('@$stationId');

  /// Returns an [AirQualityData] object given a latitude and longitude.
  Future<AirQualityData> feedFromGeoLocation(double lat, double lon) async =>
      await _airQualityFromUrl('geo:$lat;$lon');

  /// Returns an [AirQualityData] object given using the IP address.
  Future<AirQualityData> feedFromIP() async => await _airQualityFromUrl('here');

  /// Send API request given a URL
  Future<AirQualityData> _requestAirQualityFromURL(String keyword) async {
    String url = '$_endpoint/$keyword/?token=$_token';

    final response = await Dio().get(url);

    if (response.statusCode == 200) {
      return AirQualityData.fromJson(response.data);
    }
    throw AirQualityAPIException("OpenWeather API Exception: ${response.data}");
  }

  Future<AirQualityData> _airQualityFromUrl(String url) async {
    AirQualityData airQualityJson = await _requestAirQualityFromURL(url);
    return airQualityJson;
  }
}
