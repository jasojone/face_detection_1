import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home.dart';

List<CameraDescription>? cameras;

// Main function that calls runApp on our root widget.
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root widget of the application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Face Detector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}