import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_ml_text_kit/main.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Need camera permission")));
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController =
          CameraController(_cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController?.startImageStream((image) async {
        if (!isBlocked) {
          isBlocked = true;
          logger.e('dongds scan: ${image.format.raw}');
          await _takePictureAndScan();
        }
      });
    }
  }

  Future<void> _takePictureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      isBlocked = false;
      return;
    }

    try {
      await _cameraController!.takePicture().then((XFile file) async {
        final File imageFile = File(file.path);
        await _scanText(imageFile);
      });
    } catch (e) {
      isBlocked = false;
      if (kDebugMode) {
        print("Take picture error: $e");
      }
    }
  }

  Future<void> _scanText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final text = recognizedText.text.toUpperCase().split(RegExp(r'\r?\n'));
    final blocks = recognizedText.blocks;

    String name = text[2];
    String address = '${text[3]}\n${text[4]}';
    String dob = "";
    String licenceNo = "";

    for (TextBlock block in blocks) {
      final text = block.text.toUpperCase();

      // Tìm ngày sinh (DATE OF BIRTH)
      if (text.contains("DATE OF BIRTH")) {
        dob = text.split("DATE OF BIRTH")[1].trim().split(" ")[0];
      }

      // Tìm số bằng lái (LICENCE NO)
      if (text.contains("LICENCE NO")) {
        licenceNo = text.split("LICENCE NO")[1].trim().split(" ")[0];
      }
    }

    if (name.isNotEmpty &&
        address.isNotEmpty &&
        dob.isNotEmpty &&
        licenceNo.isNotEmpty) {
      textRecognizer.close();
      Navigator.pop(context, {
        "Name": name,
        "Address": address,
        "DateOfBirth": dob,
        "LicenceNo": licenceNo,
      });
    }
    isBlocked = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan ID"),
      ),
      body: Column(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : Container(height: 200, color: Colors.black),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
