import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:soundsense/classifier.dart';
import 'package:soundsense/classifier_quant.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraController? _camController;
  SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';

  late Classifier _classifier;
  Category? category;

  File? _image;
  Image? _imageWidget;

  var logger = Logger();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeCamera();
    _initSpeech();
    _classifier = ClassifierQuant();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void initializeCamera() async {
    final cameras = await availableCameras();
    _camController = CameraController(cameras[0], ResolutionPreset.medium);
    _camController?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    _camController?.lockCaptureOrientation(DeviceOrientation.landscapeRight);
  }

  Future takePicture() async {
    await _camController!.setFlashMode(FlashMode.off);
    await _camController!.setFocusMode(FocusMode.locked);
    await _camController!.setExposureMode(ExposureMode.locked);

    final picture = await _camController!.takePicture();

    await _camController!.setFocusMode(FocusMode.auto);
    await _camController!.setExposureMode(ExposureMode.auto);

    if (picture != null) {
      setState(() {
        _image = File(picture.path);
        _imageWidget = Image.file(_image!);

        _predict();
        logger.i(category!.toString());
      });
    }

    return "error";
  }

  void _predict() async {
    img.Image imageInput = img.decodeImage(_image!.readAsBytesSync())!;
    var pred = _classifier.predict(imageInput);

    setState(() {
      this.category = pred;
    });
  }

  Future<void> _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
    );
    setState(() {});
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_camController == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: () => {takePicture()},
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(
            _camController!,
            child: Center(
              child: Text(
                category != null ? category!.label : "",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
