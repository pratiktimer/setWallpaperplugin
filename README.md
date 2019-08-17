# wallpaper

wallpaper plugin to set wallpaper from url in android
## Usage
To use this plugin, add `wallpaper: ^0.0.9` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wallpaper/wallpaper.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String home = "Home Screen", lock = "Lock Screen", both = "Both Screen";
  Stream<String> progressString;
  String res;
  bool downloading = false;
  List<String> images = [
    "https://images.pexels.com/photos/2772854/pexels-photo-2772854.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/1368388/pexels-photo-1368388.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/2417842/pexels-photo-2417842.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500"
  ];
  var result = "Waiting to set wallpaper";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          margin: EdgeInsets.only(top: 20),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Image.network(
                      images[0],
                      fit: BoxFit.fitWidth,
                    ),
                    Positioned(
                      left: 10,
                      bottom: 0,
                      child: RaisedButton(
                        onPressed: () {
                          progressString =
                              Wallpaper.ImageDownloadProgress(images[0]);
                          progressString.listen((data) {
                            setState(() {
                              res = data;
                              downloading = true;
                            });
                            print("DataReceived: " + data);
                          }, onDone: () async {
                            home = await Wallpaper.homeScreen();
                            setState(() {
                              downloading = false;
                              home = home;
                            });
                            print("Task Done");
                          }, onError: (error) {
                            setState(() {
                              downloading = false;
                            });
                            print("Some Error");
                          });
                        },
                        textColor: Colors.white,
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFF0D47A1),
                                  Color(0xFF1976D2),
                                  Color(0xFF42A5F5),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            child: Text(home, style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    Dialog()
                  ],
                ),
                Stack(
                  children: <Widget>[
                    Image.network(
                      images[1],
                      fit: BoxFit.fitWidth,
                    ),
                    Positioned(
                      left: 10,
                      bottom: 0,
                      child: RaisedButton(
                        onPressed: () {
                          progressString =
                              Wallpaper.ImageDownloadProgress(images[1]);
                          progressString.listen((data) {
                            setState(() {
                              res = data;
                              downloading = true;
                            });
                            print("DataReceived: " + data);
                          }, onDone: () async {
                            lock = await Wallpaper.lockScreen();
                            setState(() {
                              downloading = false;
                              lock = lock;
                            });
                            print("Task Done");
                          }, onError: (error) {
                            setState(() {
                              downloading = false;
                            });
                            print("Some Error");
                          });
                        },
                        textColor: Colors.white,
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFF0D47A1),
                                  Color(0xFF1976D2),
                                  Color(0xFF42A5F5),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            child: Text(lock, style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                    Dialog()
                  ],
                ),
                Stack(
                  children: <Widget>[
                    Image.network(
                      images[2],
                      fit: BoxFit.fitWidth,
                    ),
                    Positioned(
                      left: 10,
                      bottom: 0,
                      child: RaisedButton(
                        onPressed: () {
                          progressString =
                              Wallpaper.ImageDownloadProgress(images[2]);
                          progressString.listen((data) {
                            setState(() {
                              res = data;
                              downloading = true;
                            });
                            print("DataReceived: " + data);
                          }, onDone: () async {
                            both = await Wallpaper.bothScreen();
                            setState(() {
                              downloading = false;
                              both = both;
                            });
                            print("Task Done");
                          }, onError: (error) {
                            setState(() {
                              downloading = false;
                            });
                            print("Some Error");
                          });
                        },
                        textColor: Colors.white,
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color(0xFF0D47A1),
                                  Color(0xFF1976D2),
                                  Color(0xFF42A5F5),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            child: Text(both, style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                    Dialog()
                  ],
                ),
              ],
            ),
          )),
    );
  }

  Widget Dialog() {
    return Positioned(
      top: 200,
      left: 70,
      child: downloading
          ? Container(
              height: 120.0,
              width: 200.0,
              child: Card(
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 20.0),
                    Text(
                      "Downloading File : $res",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            )
          : Text(""),
    );
  }
}


```
## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.io/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
