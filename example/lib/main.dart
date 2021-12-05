import 'dart:async';
import 'dart:math';

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
      system = "System";

  Stream<String> progressString;
  String res;
  bool downloading = false;
  List<String> images = [
    "https://images.pexels.com/photos/10069890/pexels-photo-10069890.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/7037125/pexels-photo-7037125.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/8803905/pexels-photo-8803905.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/9556451/pexels-photo-9556451.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/10050591/pexels-photo-10050591.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/9000160/pexels-photo-9000160.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/9676202/pexels-photo-9676202.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
    "https://images.pexels.com/photos/9308054/pexels-photo-9308054.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500"
  ];
  var result = "Waiting to set wallpaper";
  bool _isDisable = true;

  int nextImageID = 0;

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
                downloading
                    ? imageDownloadDialog()
                    : Image.network(
                        images[nextImageID],
                        fit: BoxFit.fitWidth,
                      ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      nextImageID = Random().nextInt(images.length);
                      _isDisable = true;

                    });
                  },
                  child: Text("Get Random Image"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    return await dowloadImage(context);
                  },
                  child: Text("please download the image"),
                ),
                ElevatedButton(
                  onPressed: _isDisable
                      ? null
                      : () async {
                          var width = MediaQuery.of(context).size.width;
                          var height = MediaQuery.of(context).size.height;
                          home = await Wallpaper.homeScreen(
                              options: RequestSizeOptions.RESIZE_FIT,
                              width: width,
                              height: height);
                          setState(() {
                            downloading = false;
                            home = home;
                          });
                          print("Task Done");
                        },
                  child: Text(home),
                ),
                ElevatedButton(
                  onPressed: _isDisable
                      ? null
                      : () async {
                          lock = await Wallpaper.lockScreen();
                          setState(() {
                            downloading = false;
                            lock = lock;
                          });
                          print("Task Done");
                        },
                  child: Text(lock),
                ),
                ElevatedButton(
                  onPressed: _isDisable
                      ? null
                      : () async {
                          both = await Wallpaper.bothScreen();
                          setState(() {
                            downloading = false;
                            both = both;
                          });
                          print("Task Done");
                        },
                  child: Text(both),
                ),
                ElevatedButton(
                  onPressed: _isDisable
                      ? null
                      : () async {
                    system = await Wallpaper.systemScreen();
                          setState(() {
                            downloading = false;
                            system = system;
                          });
                          print("Task Done");
                        },
                  child: Text(system),
                ),
              ],
            ),
          )),
    );
  }

  Future<void> dowloadImage(BuildContext context) async {
    progressString = Wallpaper.imageDownloadProgress(
      images[nextImageID]

    );
    progressString.listen((data) {
      setState(() {
        res = data;
        downloading = true;
      });
      print("DataReceived: " + data);
    }, onDone: () async {
      setState(() {
        downloading = false;

        _isDisable = false;
      });
      print("Task Done");
    }, onError: (error) {
      setState(() {
        downloading = false;
        _isDisable = true;
      });
      print("Some Error");
    });
  }

  Widget imageDownloadDialog() {
    return Container(
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
    );
  }
}
