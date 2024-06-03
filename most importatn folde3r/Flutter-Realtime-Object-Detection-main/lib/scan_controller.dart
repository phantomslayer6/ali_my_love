import 'dart:async' show Future, StreamController;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  var isCameraInitialized = false.obs;
  bool isProcessingFrame = false;
  final StreamController<CameraImage> _imageStreamController =
      StreamController<CameraImage>();
  var results = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFlite();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _imageStreamController.close();
    Tflite.close();
    super.dispose();
  }

  Future<void> initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize().then((_) {
        cameraController.startImageStream((image) {
          if (!_imageStreamController.isClosed) {
            _imageStreamController.add(image);
          }
        });

        _imageStreamController.stream.listen((image) {
          if (!isProcessingFrame) {
            isProcessingFrame = true;
            objectDetector(image);
          }
        });

        isCameraInitialized.value = true;
        update();
      }).catchError((e) {
        print("Camera initialization error: $e");
        Get.dialog(
          AlertDialog(
            title: const Text('Camera Error'),
            content: Text('Error initializing camera: $e'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    } else {
      print("Camera permission denied");
      Get.dialog(
        AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text('Camera permission is required to use this app.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> initTFlite() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false,
      );
    } catch (e) {
      print("Failed to load TFLite model: $e");
      Get.dialog(
        AlertDialog(
          title: const Text('Model Error'),
          content: Text('Error loading TFLite model: $e'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> objectDetector(CameraImage image) async {
    try {
      var resultsList = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.4,
        asynch: true,
      );

      if (resultsList != null) {
        results.value = resultsList.map((result) => result['label']).join(", ");
        update(); // Notify the UI about the change
      }
    } catch (e) {
      print("Error during object detection: $e");
    } finally {
      isProcessingFrame = false;
    }
  }
}
