import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'dart:io';


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:location/location.dart';
import 'package:temperaturemonitor/air_quality_services.dart';
import 'package:temperaturemonitor/model/air_quality_data.dart';
import 'package:vibration/vibration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cron/cron.dart';
import 'package:intl/intl.dart';





enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

class Home extends StatefulWidget {

  final double temperature;
  final double humidity;
  final String title;
  final double aqi;
  final BluetoothDevice device;
  final int index;

  const Home({
    Key key,
    this.temperature,
    this.humidity,
    this.title,
    this.aqi,
    this.device,
    this.index,

  }) : super(key: key);
  _HomeState createState() => _HomeState();
}


class _HomeState extends State<Home> {
  String message;

  String _content = 'Unknown';
  String _key = '15d59eef9e612c58a5e39e1b52f718fb42bf1e79';
  String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  AirQuality _airQuality;
  AirQualityData airQualityIndex;
  AppState _state = AppState.NOT_DOWNLOADED;
  List<AirQualityData> _data;
  double lat, lng;
  List<String> _temphumidata = [];
  var _temperature = 0.0;
  var _humidity = 0.0;
  int _index =0;



  Stream<List<int>> stream;

  void initState() {
    super.initState();
    _airQuality = AirQuality(_key);
    discoverServices();
    findLatLng();
    final cron = Cron();
    cron.schedule(Schedule.parse('*/5 * * * *'), () async {
      download();
    });

  }
  discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == serviceUuid) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == characteristicUuid) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            setState(() {
              stream = characteristic.value;
            });
          }
        });
      }
    });
  }


  Future download() async {

    _data = [];
    setState(() {
      _state = AppState.DOWNLOADING;
    });
    AirQualityData feedFromGeoLocation =
    await _airQuality.feedFromGeoLocation(lat, lng);
    setState(() {
      _data.add(feedFromGeoLocation);
    });
    setState(() {
      _state = AppState.FINISHED_DOWNLOADING;
    });
    Map<String, dynamic> map = Map();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    map['0date'] = formattedDate.toString();
    map['index'] = _data[_index].airQualityIndex.toString();
    map['level'] = _data[_index].airQualityLevel.toString();
    map['place'] = _data[_index].place.toString();
    map['1temperature'] = _temperature.toString();
    map['2humidity'] = _humidity.toString();
    if ((_humidity >= 50.00 || _humidity <= 85.00) &
    (_temperature >= 23.00 || _temperature <= 26.00) ){
      map['status'] = 'Mask is not wearing';
    }
    if ((_humidity >= 75.00 && (_humidity <= 100.00)) &&
        (_temperature >= 32.00 && _temperature <= 38.00)) {
      map['status'] = 'Mask is wearing';
    }

      return FirebaseFirestore.instance.collection('pm2.5').doc().set(map).then((value){
        });
  }


  Widget contentFinishedDownload() {

    if ((_humidity >= 75.00 && (_humidity <= 100.00)) &&
        (_temperature >= 32.00 && _temperature <= 38.00)) {
      Vibration.cancel();

    }
    if ((_humidity >= 75.00 && (_humidity <= 100.00)) &&
        (_temperature >= 32.00 && _temperature <= 38.00)&(_data[_index].airQualityIndex.toInt()  <= 100)) {
      Vibration.cancel();

    }

    else if((_humidity >= 50.00 || _humidity <= 85.00) &
    (_temperature >= 23.00 || _temperature <= 26.00) &(_data[_index].airQualityIndex.toInt()  >= 100)){
      Vibration.vibrate(pattern: [500, 1000, 500, 2000]);


    }
    return Center(
      child: Card(
        child: Container(
          width: 380,
          height: 205,
          child: ListView.separated(
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return Column(

                children: [
                  ListTile(
                    title: Text(_data[index].airQualityIndex.toString(),style: TextStyle (fontSize: 65.0),textAlign: TextAlign.center),
                  ),
                  ListTile(
                   title: Text(_data[index].airQualityLevel.toString()),
                  ),
                  ListTile(
                    title: Text(_data[index].place.toString()),
                  )

                ],

              );

            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          ),
        ),
       color: (_data[_index].airQualityIndex.toInt()  <= 100)?Colors.green :Colors.red,

      ),
    );
  }

  Widget contentDownloading() {
    return Container(
      margin: EdgeInsets.all(25),
      child: Column(
        children: [
          Text(
            'Fetching Air Quality...',
            style: TextStyle(fontSize: 20),
          ),
          Container(
            margin: EdgeInsets.only(top: 50),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget contentNotDownloaded() {
    Widget content;
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            String currentValue = utf8.decode(snapshot.data);
            _temphumidata = currentValue.split(",");
            if (_temphumidata[0] != "nan" && _temphumidata[1] != "nan") {
              _temperature = double.parse(_temphumidata[0]);
              _humidity = double.parse(_temphumidata[1]);
            }

            if ((_humidity >= 75.00 && (_humidity <= 100.00)) &&
                (_temperature >= 32.00 && _temperature <= 38.00)) {
              Vibration.cancel();
              content = Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/wear.png'),
                    SizedBox(height: 10),
                    Text(
                      'Mask is \n wearing',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 35,
                        color: const Color(0xff47455f),
                        fontWeight: FontWeight.w900,

                      ),
                      textAlign: TextAlign.center,
                    )

                  ],
                ),
              );
            } else if ((_humidity >= 50.00 || _humidity <= 85.00) &
            (_temperature >= 23.00 || _temperature <= 26.00) ) {


              content = Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/not wear.png'),
                    SizedBox(height: 10),
                    Text(
                      'Mask is \n not wearing',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 35,
                        color: const Color(0xff47455f),
                        fontWeight: FontWeight.w900,

                      ),
                      textAlign: TextAlign.center,
                    )


                  ],
                ),
              );
            }

          }
        } else {
          content = Center(
            child: CircularProgressIndicator(),
          );
        }
        return content;
      },
    );
  }

  Future<Null> findLatLng() async {
    LocationData locationData = await findLocationData();
    lat = locationData.latitude;
    lng = locationData.longitude;
    print('lat=$lat, lng=$lng');
  }

  Future<LocationData> findLocationData() async {
    Location location = Location();
    try {
      return location.getLocation();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    showContent() {
      switch (_state) {
        case AppState.FINISHED_DOWNLOADING:
          return contentFinishedDownload();
          break;
        case AppState.DOWNLOADING:
          return contentDownloading();
          break;
        default:
          return Container();
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        contentNotDownloaded(),
        showContent(),


        RaisedButton(



          onPressed: download,



          child: Icon(Icons.cloud_download),

        ),

      ],
    );
  }
}
