

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isDetecting = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face> facesList = [];
  CameraDescription? cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;



  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
