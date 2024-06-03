import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'scan_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return Stack(
            children: [
              controller.isCameraInitialized.value
                  ? CameraPreview(controller.cameraController)
                  : const Center(child: CircularProgressIndicator()),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    controller.results.value,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
