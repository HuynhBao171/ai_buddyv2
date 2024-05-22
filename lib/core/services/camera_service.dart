import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  String? _imagePath;

  String? get imagePath => _imagePath;

  Future<void> initialize() async {
    if (await Permission.camera.request().isGranted) {
      _cameras = await availableCameras();
      _controller = CameraController(
          _cameras[1], ResolutionPreset.medium); // Sử dụng camera trước
      await _controller?.initialize();
    }
  }

  Future<String?> takePicture() async {
    if (!_controller!.value.isInitialized) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();

    final imagePath = join(
      directory.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await _controller?.takePicture().then((file) {
      _imagePath = imagePath;
      file.saveTo(imagePath);
    });

    return _imagePath;
  }

  Future<List<String?>> takeMultiplePictures() async {
    final List<String?> imagePaths = [];

    for (int i = 0; i < 3; i++) {
      final imagePath = await takePicture();
      if (imagePath != null) {
        imagePaths.add(imagePath);
      }
    }

    return imagePaths;
  }

  void dispose() {
    _controller?.dispose();
  }
}
