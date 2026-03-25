import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class to save files to public device storage.
/// - Images → Pictures/DocuMaster (visible in Gallery)
/// - PDFs → Documents/DocuMaster (visible in File Manager)
class FileSaverHelper {
  static const String _appFolder = 'DocuMaster';
  static const MethodChannel _channel = MethodChannel('com.documaster/file_saver');

  /// Saves a file to public storage and returns the new public path.
  /// For images: saves to Pictures/DocuMaster
  /// For PDFs: saves to Documents/DocuMaster
  static Future<String> saveToPublicStorage({
    required String sourcePath,
    required String fileName,
    required bool isImage,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    if (Platform.isAndroid) {
      return await _saveToAndroidPublicStorage(
        sourceFile: sourceFile,
        fileName: fileName,
        isImage: isImage,
      );
    } else if (Platform.isIOS) {
      return await _saveToIOSPublicStorage(
        sourceFile: sourceFile,
        fileName: fileName,
        isImage: isImage,
      );
    }

    // Fallback: return the source path as-is
    return sourcePath;
  }

  static Future<String> _saveToAndroidPublicStorage({
    required File sourceFile,
    required String fileName,
    required bool isImage,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final result = await _channel.invokeMethod<String>('saveFile', {
        'bytes': bytes,
        'fileName': fileName,
        'isImage': isImage,
        'appFolder': _appFolder,
      });
      return result ?? sourceFile.path;
    } on PlatformException {
      // Fallback: save to public external storage directory manually
      return await _fallbackSave(
        sourceFile: sourceFile,
        fileName: fileName,
        isImage: isImage,
      );
    }
  }

  static Future<String> _saveToIOSPublicStorage({
    required File sourceFile,
    required String fileName,
    required bool isImage,
  }) async {
    if (isImage) {
      try {
        final bytes = await sourceFile.readAsBytes();
        await _channel.invokeMethod('saveImageToGallery', {
          'bytes': bytes,
          'fileName': fileName,
        });
        return sourceFile.path;
      } on PlatformException {
        return sourceFile.path;
      }
    } else {
      // For PDFs on iOS, save to app's documents directory (accessible via Files app)
      final docsDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${docsDir.path}/$_appFolder');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      final destFile = File('${outputDir.path}/$fileName');
      await sourceFile.copy(destFile.path);
      return destFile.path;
    }
  }

  static Future<String> _fallbackSave({
    required File sourceFile,
    required String fileName,
    required bool isImage,
  }) async {
    // Fallback: use external storage directory
    String basePath;
    if (isImage) {
      basePath = '/storage/emulated/0/Pictures/$_appFolder';
    } else {
      basePath = '/storage/emulated/0/Documents/$_appFolder';
    }

    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final destFile = File('${dir.path}/$fileName');
    await sourceFile.copy(destFile.path);
    return destFile.path;
  }
}
