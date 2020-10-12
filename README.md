# wallpaper

wallpaper plugin to set wallpaper from url in android
## Usage
To use this plugin, add `wallpaper: ^1.0.6` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

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
  String home = "Home Screen",
      lock = "Lock Screen",
      both = "Both Screen",
      system="System";

  Stream<String> progressString;
  String res;
  bool downloading = false;
  List<String> images = [
    "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/63fd4930-a5a7-4193-8899-4d98f8d8f640/d7z4roz-83fae3a1-6147-459a-9567-ecaaa71e32c5.jpg/v1/fill/w_233,h_350,q_70,strp/lonesome_lake__me_modeling__by_gestiefeltekatze_d7z4roz-350t.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3siaGVpZ2h0IjoiPD05MDAiLCJwYXRoIjoiXC9mXC82M2ZkNDkzMC1hNWE3LTQxOTMtODg5OS00ZDk4ZjhkOGY2NDBcL2Q3ejRyb3otODNmYWUzYTEtNjE0Ny00NTlhLTk1NjctZWNhYWE3MWUzMmM1LmpwZyIsIndpZHRoIjoiPD02MDAifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6aW1hZ2Uub3BlcmF0aW9ucyJdfQ.stxfsYr5HNVZrDqAGTnldIRojCdQh4BZ-Sisy1ZU9B8",
    "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/c441181a-5c01-4d2c-98fa-3546e0f90b98/dbdqoxj-1807b4cb-28f6-4827-86ca-ffe5e0466369.jpg/v1/fill/w_280,h_350,q_70,strp/yennefer_by_melamaika_dbdqoxj-350t.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3siaGVpZ2h0IjoiPD0xMDA1IiwicGF0aCI6IlwvZlwvYzQ0MTE4MWEtNWMwMS00ZDJjLTk4ZmEtMzU0NmUwZjkwYjk4XC9kYmRxb3hqLTE4MDdiNGNiLTI4ZjYtNDgyNy04NmNhLWZmZTVlMDQ2NjM2OS5qcGciLCJ3aWR0aCI6Ijw9ODA1In1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmltYWdlLm9wZXJhdGlvbnMiXX0.psIqysnwqd34k-63vXc-fp-N0QKfhgx58UyRYa_p41E",
    "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/5de16715-76bd-4cf7-bd5f-f12445a53f38/dbdecvm-afd763c3-d050-49f1-9794-e409270935b4.jpg/v1/fit/w_300,h_900,q_70,strp/butterflies_in_my_stomach_by_anyaanti_dbdecvm-300w.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3siaGVpZ2h0IjoiPD05MDAiLCJwYXRoIjoiXC9mXC81ZGUxNjcxNS03NmJkLTRjZjctYmQ1Zi1mMTI0NDVhNTNmMzhcL2RiZGVjdm0tYWZkNzYzYzMtZDA1MC00OWYxLTk3OTQtZTQwOTI3MDkzNWI0LmpwZyIsIndpZHRoIjoiPD05MDAifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6aW1hZ2Uub3BlcmF0aW9ucyJdfQ.UVP-S5RXr2g404JUlQCddufehCrb2N5tXL6CwzBJ88g",
    "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/c441181a-5c01-4d2c-98fa-3546e0f90b98/dbdqoxj-1807b4cb-28f6-4827-86ca-ffe5e0466369.jpg/v1/fill/w_280,h_350,q_70,strp/yennefer_by_melamaika_dbdqoxj-350t.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOiIsImlzcyI6InVybjphcHA6Iiwib2JqIjpbW3siaGVpZ2h0IjoiPD0xMDA1IiwicGF0aCI6IlwvZlwvYzQ0MTE4MWEtNWMwMS00ZDJjLTk4ZmEtMzU0NmUwZjkwYjk4XC9kYmRxb3hqLTE4MDdiNGNiLTI4ZjYtNDgyNy04NmNhLWZmZTVlMDQ2NjM2OS5qcGciLCJ3aWR0aCI6Ijw9ODA1In1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmltYWdlLm9wZXJhdGlvbnMiXX0.psIqysnwqd34k-63vXc-fp-N0QKfhgx58UyRYa_p41E"
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
          width: MediaQuery
              .of(context)
              .size
              .width,
          height: MediaQuery
              .of(context)
              .size
              .height,
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
                            var width=  MediaQuery
                                .of(context)
                                .size
                                .width;
                            var height =  MediaQuery
                                .of(context)
                                .size
                                .height;
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
                Stack(
                  children: <Widget>[
                    Image.network(
                      images[3],
                      fit: BoxFit.fitWidth,
                    ),
                    Positioned(
                      left: 10,
                      bottom: 0,
                      child: RaisedButton(
                        onPressed: () {
                          progressString =
                              Wallpaper.ImageDownloadProgress(images[3]);
                          progressString.listen((data) {
                            setState(() {
                              res = data;
                              downloading = true;
                            });
                            print("DataReceived: " + data);
                          }, onDone: () async {
                            both = await Wallpaper.systemScreen(location: DownloadLocation.APPLICATION_DIRECTORY);
                            setState(() {
                              downloading = false;
                              system = system;
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
                            child: Text(system, style: TextStyle(fontSize: 14)),
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
