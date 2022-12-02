

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
    // initCamera is called in initState so it is guaranteed to be called before
    // the first frame is rendered. This means that the camera is initialized
    // before the first frame is rendered. This is important because the camera
    // is initialized asynchronously and we want to make sure that the camera is
    // initialized before we start rendering the camera preview.
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
    //performDetectionOnStreamFrames is called in the imageStream callback. This
    //means that it is called every time a new frame is rendered. This is
    //important because we want to perform the detection on every frame.
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
    //initState is called before the first frame is rendered. This means that
    //initCamera is called before the first frame is rendered. This is important
    //because the camera is initialized asynchronously and we want to make sure
    //that the camera is initialized before we start rendering the camera preview.
    super.initState();
    initCamera();

  }

  @override
  void dispose() {
    //dispose is called when the widget is removed from the widget tree. This
    //means that the camera is disposed when the widget is removed from the
    //widget tree. This is important because the camera is disposed
    //asynchronously and we want to make sure that the camera is disposed before
    //we remove the widget from the widget tree.

    super.dispose();
    cameraController?.dispose();
    faceDetector!.close();
  }

  Widget buildResult(){
    //buildResult is called in the build method. This means that it is called
    //every time the build method is called. This is important because we want
    //to display the results every time the build method is called.
    if (scanResults == null || cameraController == null || !cameraController!.value.isInitialized) {
      return const Text("");
    }
    final Size imageSize = Size(cameraController!.value.previewSize!.height, cameraController!.value.previewSize!.width);
    CustomPainter customPainter = FaceDetectorPainter(imageSize, scanResults, cameraLensDirection);
    return CustomPaint(painter: customPainter,);

  }
  toggleCameraToFrontOrBack()async{
    //toggleCameraToFrontOrBack is called when the user taps on the camera
    //toggle button. This means that the camera is toggled when the user taps on
    //the camera toggle button. This is important because we want to toggle the
    //camera when the user taps on the camera toggle button.
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
    //build is called every time the state changes. This means that the camera
    //preview is rendered every time the state changes. This is important because
    //we want to render the camera preview every time the state changes.
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