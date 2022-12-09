import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'utils_scanner.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

// This class is the configuration for the state. It holds the values associated with the camera and facial detection
// and is used by the build method of the State.
class _HomeState extends State<Home> {

  bool isWorking = false;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  Size? size;
  List<Face> facesList = [];
  CameraDescription? cameraDescription;
  CameraLensDirection cameraLensDirection = CameraLensDirection.front;
  double? smileProb = 0;
  dynamic scanResults;

  // Called when this object is inserted into the widget tree.
  // We first call the base class initState function, and then initialize the camera.
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  // Called when this object is removed from the widget tree permanently.
  // This stage of the the objects lifecycle is terminal; there is no way to remount
  // a State object that has been disposed.
  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
    faceDetector!.close();
  }

  // Describes the part of the UI represented by the widget.
  // Framework calls this method when widget is inserted into the tree after initState()
  @override
  Widget build(BuildContext context) {
    List<Widget> stackWidgetChildren = [];
    size = MediaQuery.of(context).size;

    // Add UI camera display widget to list
    if(cameraController != null){
      stackWidgetChildren.add(
        Positioned(
          top: 0,
          left: 0,
          width: size!.width,
          height: size!.height-150,
          child: Container(
            child:(cameraController!.value.isInitialized) ?
                  AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  )
                : Container(
                  color : Colors.black,
                ),
          ),
        ),
      );
    }

    // Add UI for facial detection graphics widget to list
    stackWidgetChildren.add(
      Positioned(
        top: 0,
        left: 0.0,
        width: size!.width,
        height: size!.height-150,
        child: buildResult(),
      )
    );

    // Add UI for button widget to list
    stackWidgetChildren.add(
        Positioned(
          top: size!.height-150,
          left: 0.0,
          width: size!.width,
          height: 250,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: (){
                      toggleCameraToFrontOrBack();
                    },
                    icon: const Icon(Icons.cached, color: Colors.white,),
                    iconSize: 60,
                    color: const Color.fromARGB(255, 57, 57, 57),
                ),
              ],
            ),
          ),
        )
      );

    // build returns Scaffold widget with the stackWidgetChildren list as a child
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackWidgetChildren,
        ),
      ),
    );
  }

  // This function is called in initstate().
  // The UtilScanner class is used to get the camera information which is passed to a dart CameraController.
  // We also initialize the ML face detector class from firebase in this function, and when the camera is initialized
  // we perform ML facial detection on the stream provided by the camera.
  initCamera()async{
    cameraDescription = await UtilsScanner.getCamera(cameraLensDirection);
    cameraController = CameraController(cameraDescription!, ResolutionPreset.high);
    faceDetector = FirebaseVision.instance.faceDetector(const FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
      mode: FaceDetectorMode.accurate,
    ));
    await cameraController!.initialize().then((value){
      if (!mounted) {
        return;
      }
      //If we are not performing detection, take in imagestream and perform detection
      cameraController!.startImageStream((imageFromStream) => {
        if(!isWorking){
          isWorking = true,
          performDetectionOnStreamFrames(imageFromStream),
        }
        });
    });
  }

  // This function is called when the user taps on the switch camera button and switches the camera direction
  // before stopping the image stream and disposing of the CameraController object.
  toggleCameraToFrontOrBack() async {
    if(cameraLensDirection == CameraLensDirection.back){
      cameraLensDirection = CameraLensDirection.front;
    } else {
      cameraLensDirection = CameraLensDirection.back;
    }
    await cameraController!.stopImageStream();
    await cameraController!.dispose();

    // Notifies the framework the internal state of the widget has changes and needs to be rebuilt.
    setState(() {
      cameraController = null;
    });
    initCamera();
  }

  // performDetectionOnStreamFrames is called in the imageStream callback for every available frame.
  // We use the detect method from our UtilsScanner class  
  performDetectionOnStreamFrames(CameraImage cameraImage) async {
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

  // This is called in build(). It gets data from the camera controller and then creates a new instance of a FaceDetectorPainter,
  // which is used to return a CustomPaint widget, a widget that paints graphics.
  Widget buildResult(){
    if (scanResults == null || cameraController == null || !cameraController!.value.isInitialized) {
      return const Text("");
    }
    final Size imageSize = Size(cameraController!.value.previewSize!.height, cameraController!.value.previewSize!.width);
    CustomPainter customPainter = FaceDetectorPainter(imageSize, scanResults, cameraLensDirection, smileProb!);
    return CustomPaint(painter: customPainter,);
  }
}

// This class is inherits from CustomPainter interface, and is essentially used to
// generate graphics related to the facial detection data passed in.
class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.facesList, this.cameraLensDirection, this.smileProb);

  final Size absoluteImageSize;
  final List<Face> facesList;
  CameraLensDirection cameraLensDirection;
  double smileProb;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    // Cascade Notation Operator used
    // Allows performance of a sequence of methods on same object
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.green;

    final Paint paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (Face face in facesList) {
      smileProb = face.smilingProbability;

      //Draw rectangles based on face data
      canvas.drawRect(
          Rect.fromLTRB(
            cameraLensDirection == CameraLensDirection.front?(absoluteImageSize.width - face.boundingBox.right) * scaleX:face.boundingBox.left * scaleX,
            face.boundingBox.top * scaleY,
            cameraLensDirection == CameraLensDirection.front?(absoluteImageSize.width - face.boundingBox.left) * scaleX:face.boundingBox.right * scaleX,
            face.boundingBox.bottom * scaleY,
          ),
          (smileProb > .75)  ? paint2 : paint,
      );
      
      // Generate text for smile prediction below each box containing a face
      if (face.boundingBox.size.height > 0.5) {
        TextSpan span = TextSpan(
          style: const TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
          text: smileProb.toStringAsPrecision(2)
          );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          textScaleFactor: face.boundingBox.size.width/250
          );
        tp.layout();
        tp.paint(
          canvas,
          Offset(
            cameraLensDirection == CameraLensDirection.front?(absoluteImageSize.width - face.boundingBox.right) * scaleX:face.boundingBox.left * scaleX,
            face.boundingBox.bottomCenter.dy * scaleY,
          )
        );
      }
    }
  }

  // Called whenever a new instance of the custom painter delegate class is provided to the object.
  // If it is changed then repaint.
  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.facesList != facesList;
  }
}

