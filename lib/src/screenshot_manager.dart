import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotManager {
  static final ScreenshotController screenshotController =
      ScreenshotController();

  static Future<void> captureAndSave(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName.png';

    final image = await screenshotController.capture();
    if (image != null) {
      final file = File(filePath);
      await file.writeAsBytes(image);
    }
  }
}
