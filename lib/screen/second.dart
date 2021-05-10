import 'package:flutter/material.dart';
import 'package:temperaturemonitor/screen/home.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
class SecondScreens extends StatefulWidget{
  @override
  _SecondScreensState createState() => _SecondScreensState();
}

class _SecondScreensState extends State<SecondScreens> {
  List userProfileList = [];
  @override
  void initState() {
    super.initState();
    getDriversList().then((results) {
      setState(() {
        querySnapshot = results;
      });
    });
  }

  QuerySnapshot querySnapshot;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('History'),
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
      body: _showDrivers(),
    );
  }

  //build widget as prefered
  //i'll be using a listview.builder
  Widget _showDrivers() {

    //check if querysnapshot is null
    if (querySnapshot != null) {

      return ListView.builder(
        primary: false,
        itemCount: querySnapshot.docs.length,
        padding: EdgeInsets.all(12),
        itemBuilder: (context, i) {


          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //load data into widgets
              ListTile(
                title: Text("${querySnapshot.docs[i].data()['0date']}",style: TextStyle (fontSize: 13.0),textAlign:  TextAlign.center),
              ),
              /*Container(
                  decoration: BoxDecoration(color: Colors.pink[400],borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text("${querySnapshot.docs[i].data()['0date']}",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )),*/

              // Segment 2
              Container(
                decoration: BoxDecoration(color: Colors.blue[100],borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("              ${querySnapshot.docs[i].data()['status']}                         ${querySnapshot.docs[i].data()['index']} = ${querySnapshot.docs[i].data()['level']}    ${querySnapshot.docs[i].data()['place']} "  , style: TextStyle(fontSize: 14, color: Colors.brown)),
              ),

              // Segment 3
              /* Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("${querySnapshot.docs[i].data()['level']}", style: TextStyle(fontSize: 20, color: Colors.pink[400])),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("${querySnapshot.docs[i].data()['place']}", style: TextStyle(fontSize: 20, color: Colors.pink[400])),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("${querySnapshot.docs[i].data()['status']}", style: TextStyle(fontSize: 20, color: Colors.pink[400])),
              ),*/

            ],
          );
        },
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  //get firestore instance
  getDriversList() async {
    return await FirebaseFirestore.instance.collection('pm2.5').get();
  }
}