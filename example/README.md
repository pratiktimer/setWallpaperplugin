# wallpaper_example
## Usage
To use this plugin, add `wallpaper: ^0.0.3` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:wallpaper/wallpaper.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var result = "Waiting to set wallpaper";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
              child: Container(
            width: 200,
            height: 600,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10),
                  child: RaisedButton(
                    color: Colors.black,
                    child: Text(
                      "Home Screen",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    onPressed: () async {
                      String res;
                      res = await Wallpaper.HomeScreen(
                          "https://images.pexels.com/photos/1070030/pexels-photo-1070030.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500");
                      if (!mounted) return;
                      setState(() {
                        result = res.toString();
                      });
                    },
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(10),
                    child: RaisedButton(
                      color: Colors.black,
                      child: Text(
                        "Lock Screen",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () async {
                        String res;
                        res = await Wallpaper.LockScreen(
                            "https://images.pexels.com/photos/1028225/pexels-photo-1028225.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500");
                        if (!mounted) return;
                        setState(() {
                          result = res.toString();
                        });
                      },
                    )),
                Padding(
                    padding: EdgeInsets.all(10),
                    child: RaisedButton(
                      color: Colors.black,
                      child: Text(
                        "Both",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () async {
                        String res;
                        res= await Wallpaper.Both(
                            "https://images.pexels.com/photos/1444492/pexels-photo-1444492.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500");
                        if (!mounted) return;
                        setState(() {
                          result = res;
                        });
                      },
                    )),
                Padding(
                    padding: EdgeInsets.all(10), child: Text(result.toString()))
              ],
            ),
          )),
        ));
  }
}
```



## Getting Started


This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.io/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.io/docs/cookbook)

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
