import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

// This class is used to get avilable cameras, as well as handle some
// of the functionality realted to the ML framework
class UtilsScanner{
  UtilsScanner._();

  // This fucntion returns gets the list of available cameras and then sets the
  // camera description to the first one that matches the lens direction
  static Future<CameraDescription> getCamera(CameraLensDirection cameraLensDirection) async {
    return await availableCameras().then(
            (List<CameraDescription> cameras) =>
            cameras.firstWhere(
                    (CameraDescription cameraDescription) =>
                cameraDescription.lensDirection == cameraLensDirection)
    );
  }

  // Main function to detect faces with FireBase ML Vision. Takes in the camera image and
  static Future<dynamic> detect({ required CameraImage image, required Future<dynamic> Function(FirebaseVisionImage imsge) detectInImage, required int imageRotation,}) async {
    return detectInImage(
      FirebaseVisionImage.fromBytes(
        concatenatePlanes(image.planes),
        buildMetaData(image, rotationIntToImageRotation(imageRotation)),
      ),
    );
  }

  // Puts all planes from the image data into a Uint8List and return
  static Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // Builds and returns ML Vision metadata
  static FirebaseVisionImageMetadata buildMetaData(CameraImage image, ImageRotation rotation) {
    return FirebaseVisionImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      rawFormat: image.format.raw,
      planeData: image.planes.map((Plane plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList(),
    );
  }

  // Function returns correct enum type based on rotation of device
  static ImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return ImageRotation.rotation0;
      case 90:
        return ImageRotation.rotation90;
      case 180:
        return ImageRotation.rotation180;
        default:
          assert(rotation == 270);
          return ImageRotation.rotation270;
    }
  }
}