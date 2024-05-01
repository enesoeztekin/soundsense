import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraController? _camController;
  SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeCamera();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
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

  Future<String> takePicture() async {
    await _camController!.setFlashMode(FlashMode.off);
    await _camController!.setFocusMode(FocusMode.locked);
    await _camController!.setExposureMode(ExposureMode.locked);

    final picture = await _camController!.takePicture();

    await _camController!.setFocusMode(FocusMode.auto);
    await _camController!.setExposureMode(ExposureMode.auto);

    if (picture != null) {
      return picture.path;
    }

    return "error";
  }

  @override
  Widget build(BuildContext context) {
    if (_camController == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: () => {_startListening()},
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(
            _camController!,
            child: Center(
              child: Text(
                _lastWords,
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
