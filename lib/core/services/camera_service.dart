import 'package:ai_buddy/core/logger/loggy_types.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService with ServiceLoggy {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  String? _imagePath;

  String? get imagePath => _imagePath;

  Future<void> initialize() async {
    loggy.info('Initializing camera service...');
    try {
      if (await Permission.camera.request().isGranted) {
        _cameras = await availableCameras();
        _controller = CameraController(
            _cameras[1], ResolutionPreset.medium); // Sử dụng camera trước
        await _controller?.initialize();
        loggy.info('Camera service initialized successfully.');
      } else {
        loggy.warning('Camera permission denied.');
      }
    } catch (e) {
      loggy.error('Error initializing camera service: $e');
    }
  }

  Future<String?> takePicture() async {
  loggy.info('Taking picture...');
  if (_controller != null && !_controller!.value.isInitialized) {
    loggy.warning('Camera is not initialized.');
    return null;
  }

  final directory = await getApplicationDocumentsDirectory();
  final imagePath = join(
    directory.path,
    '${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  try {
    await _controller?.takePicture().then((file) {
      loggy.info('Picture taken - path: $_imagePath');
      _imagePath = imagePath;
      file.saveTo(imagePath);
    });
    return _imagePath;
  } catch (e) {
    loggy.error('Error taking picture: $e');
    return null;
  }
}

  Future<List<String?>> takeMultiplePictures() async {
    final List<String?> imagePaths = [];

    for (int i = 0; i < 3; i++) {
      final imagePath = await takePicture();
      if (imagePath != null) {
        loggy.info('Picture $i taken successfully.');
        imagePaths.add(imagePath);
      } else {
        loggy.warning('Failed to take picture $i.');
      }
    }

    return imagePaths;
  }

  void dispose() {
    loggy.info('Disposing camera service...');
    _controller?.dispose();
  }
}
