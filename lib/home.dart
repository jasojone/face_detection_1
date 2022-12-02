

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
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  bool isWorking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face> facesList = [];
  CameraDescription? cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;

  initCamera()async{
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
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
          performDetectionOnStreamFrames(imageFromStream),
        }
        });
    });
  }
  dynamic scanResults;

  performDetectionOnStreamFrames(CameraImage cameraImage)async{
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
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

  Widget buildResult(){
    if (scanResults == null || cameraController == null || !cameraController!.value.isInitialized) {
      return const Text("");
    }
    final Size imageSize = Size(cameraController!.value.previewSize!.height, cameraController!.value.previewSize!.width);
    CustomPainter customPainter = FaceDetectorPainter(imageSize, scanResults, cameraLensDirection);
    return CustomPaint(painter: customPainter,);

  }
  toggleCameraToFrontOrBack()async{
    if(cameraLensDirection == CameraLensDirection.back){
      cameraLensDirection = CameraLensDirection.front;
    }else{
      cameraLensDirection = CameraLensDirection.back;
    }
    await cameraController!.stopImageStream();
    await cameraController!.dispose();

    setState(() {
      cameraController = null;
    });
    initCamera();
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> stackWidgetChildren = [];
    size = MediaQuery.of(context).size;
    if(cameraController != null){
      stackWidgetChildren.add(
        Positioned(
          top: 0,
          left: 0,
          width: size!.width,
          height: size!.height-250,
          child: Container(
            child: (cameraController!.value.isInitialized)
                ? AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              )
                : Container(),
          ),
        ),
      );
    }
    stackWidgetChildren.add(
      Positioned(
        top: 0,
        left: 0.0,
        width: size!.width,
        height: size!.height-250,
        child: buildResult(),
      )
    );

    stackWidgetChildren.add(
        Positioned(
          top: size!.height-250,
          left: 0.0,
          width: size!.width,
          height: 250,
          child: Container(
            margin: EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: (){
                      toggleCameraToFrontOrBack();
                    },
                    icon: Icon(Icons.cached, color: Colors.white,),
                    iconSize: 50,
                    color: Colors.black,
                )
              ],
            ),
          ),
        )
    );


    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackWidgetChildren,
        ),
      ),
    );
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
              .front?(absoluteImageSize.width - face.boundingBox.right) * scaleX:face.boundingBox.left * scaleX,
          face.boundingBox.top * scaleY,
          cameraLensDirection == CameraLensDirection
              .front?(absoluteImageSize.width - face.boundingBox.left) * scaleX:face.boundingBox.right * scaleX,
          face.boundingBox.bottom * scaleY,
          ),
          paint,
      );
    }
  }


  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.facesList != facesList;
  }
}