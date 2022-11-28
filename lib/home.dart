

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'utils_scanner.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isWorking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face> facesList = [];
  CameraDescription? cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;

  initCamera()async{
    cameraDescription = await UtilsScanner.getCamera(cameraLensDirection);
    cameraController = CameraController(cameraDescription!, ResolutionPreset.high);
    faceDetector = FirebaseVision.instance.faceDetector(const FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      mode: FaceDetectorMode.accurate,
      // enableFaceTracking: true,
    ));
    await cameraController!.initialize().then((value){
      if (!mounted) {
        return;
      }
      cameraController!.startImageStream((imageFromStream) => {
        if(!isWorking){
          isWorking = true,
        }
        });
    });
  }
  dynamic scanResults;

  performDetectionOnStreamFrames(CameraImage cameraImage)async{
    UtilsScanner.detect(
      image: cameraImage,
      detectInImage: faceDetector!.processImage,
      imageRotation: cameraDescription!.sensorOrientation,
    ).then((dynamic results) {
      setState(() {
        scanResults = results;
      });
    }).whenComplete((){
      isWorking = false;
    });
  }

  @override
  void initState() {
    super.initState();
    initCamera();

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController?.dispose();
    faceDetector!.close();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.facesList, this.cameraLensDirection);

  final Size absoluteImageSize;
  final List<Face> facesList;
  CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (Face face in facesList) {
      canvas.drawRect(
          Rect.fromLTRB(
          cameraLensDirection == CameraLensDirection
              .front?(absoluteImageSize.width - face.boundingBox.right * scaleX:face.boundingBox.left * scaleX,
          face.boundingBox.top * scaleY,
          cameraLensDirection == CameraLensDirection
              .front?(absoluteImageSize.width - face.boundingBox.left * scaleX:face.boundingBox.right * scaleX,)))
    }

  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.facesList != facesList;
  }
}