import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wallpaper/wallpaper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String> images = [
    "https://images.pexels.com/photos/1519753/pexels-photo-1519753.jpeg",
    "https://images.pexels.com/photos/1624496/pexels-photo-1624496.jpeg",
    "https://images.pexels.com/photos/1496373/pexels-photo-1496373.jpeg",
    "https://images.pexels.com/photos/1366919/pexels-photo-1366919.jpeg",
  ];

  int currentIndex = 0;

  bool downloading = false;
  bool imageReady = false;

  String progress = "";
  StreamSubscription? downloadSub;

  String homeText = "Set Home Screen";
  String lockText = "Set Lock Screen";
  String bothText = "Set Both";
  String systemText = "Set System";

  String get currentImage => images[currentIndex];

  void randomImage() {
    setState(() {
      currentIndex = Random().nextInt(images.length);
      imageReady = false;
    });
  }

  Future<void> downloadImage() async {
    setState(() {
      downloading = true;
      progress = "";
    });

    final stream = Wallpaper.imageDownloadProgress(
      currentImage,
      location: DownloadLocation.applicationDirectory,
    );

    downloadSub = stream.listen(
      (data) {
        setState(() {
          progress = data;
        });
      },
      onDone: () {
        setState(() {
          downloading = false;
          imageReady = true;
        });
      },
      onError: (_) {
        setState(() {
          downloading = false;
          imageReady = false;
        });
      },
    );
  }

  Future<void> setWallpaper(
    Future<String> task,
    Function(String) update,
  ) async {
    final result = await task;

    setState(() {
      update(result);
    });
  }

  Widget actionButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }

  Widget downloadIndicator() {
    return Card(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              "Downloading: $progress",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    downloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Wallpaper Example")),
        body: SingleChildScrollView(
          child: Column(
            children: [
              /// Image Preview
              downloading
                  ? downloadIndicator()
                  : Center(
                      child: SizedBox(
                        width: 300,
                        height: 200,
                        child: Image.network(currentImage, fit: BoxFit.cover),
                      ),
                    ),

              const SizedBox(height: 20),

              /// Random Image
              actionButton(text: "Random Image", onPressed: randomImage),

              /// Download
              actionButton(text: "Download Image", onPressed: downloadImage),

              const Divider(),

              /// Home Screen
              actionButton(
                text: homeText,
                onPressed: imageReady
                    ? () => setWallpaper(
                        Wallpaper.homeScreen(
                          width: width,
                          height: height,
                          options: RequestSizeOptions.resizeFit,
                          location: DownloadLocation.applicationDirectory,
                        ),
                        (v) => homeText = v,
                      )
                    : null,
              ),

              /// Lock Screen
              actionButton(
                text: lockText,
                onPressed: imageReady
                    ? () => setWallpaper(
                        Wallpaper.lockScreen(
                          location: DownloadLocation.applicationDirectory,
                        ),
                        (v) => lockText = v,
                      )
                    : null,
              ),

              /// Both
              actionButton(
                text: bothText,
                onPressed: imageReady
                    ? () => setWallpaper(
                        Wallpaper.bothScreen(
                          location: DownloadLocation.applicationDirectory,
                        ),
                        (v) => bothText = v,
                      )
                    : null,
              ),

              /// System
              actionButton(
                text: systemText,
                onPressed: imageReady
                    ? () => setWallpaper(
                        Wallpaper.systemScreen(
                          location: DownloadLocation.applicationDirectory,
                        ),
                        (v) => systemText = v,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
