import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:temperaturemonitor/screen/second.dart';
import 'package:vibration/vibration.dart';
import 'home.dart';

class SensorPage extends StatefulWidget {
  final BluetoothDevice device;

  const SensorPage({
    this.device,
  });

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  bool isReady;

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  void dispose() {
    super.dispose();
    disconnectFromDevice();
  }

  connectToDevice() async {
    setState(() {
      isReady = true;
    });
    if (widget.device == null) {
      _pop();
      return;
    }

    Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _pop();
      }
    });

    await widget.device.connect();
    setState(() {
      isReady = false;
    });
  }

  disconnectFromDevice() async {
    if (widget.device == null) {
      _pop();
      return;
    }

    await widget.device.disconnect();
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (context) =>
      AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you want to disconnect device and go back?'),
        actions: <Widget>[
          FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No')),
          FlatButton(

            onPressed: () {
              disconnectFromDevice();
              Navigator.of(context).pop(true);
              Vibration.cancel();
            },
            child: Text('Yes'),
          ),
        ],
      ) ??
          false,
    );
  }

  _pop() {
    Navigator.of(context).pop(true);
  }
  Widget SensorButton(){
    return IconButton(
      icon: Icon(Icons.update),
      onPressed:(){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SecondScreens()),
        );
        Vibration.cancel();
      } ,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color(0xFFE0F7FA),
        appBar: AppBar(
          centerTitle: true,
          title: Text('SwuSmartMask'),actions: <Widget>[SensorButton()],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey, Colors.red],
              ),
            ),
          ),
        ),
        body: Container(
          child: !isReady
              ? Center(
            child: Text(
              "Waiting...",
              style: TextStyle(fontSize: 24, color: Colors.red),
            ),
          )
              : Container(
            child: Home(
              device: widget.device,
            ),
          ),
        ),
      ),
    );
  }
}