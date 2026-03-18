import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  late Box _box;

  bool _isDarkMode = true;
  String _quality = 'Medium'; // Low, Medium, High
  double _storageUsed = 0;

  bool get isDarkMode => _isDarkMode;
  String get quality => _quality;
  double get storageUsed => _storageUsed;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _isDarkMode = _box.get('isDarkMode', defaultValue: true);
    _quality = _box.get('quality', defaultValue: 'Medium');
    _storageUsed = _box.get('storageUsed', defaultValue: 0.0);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _box.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setQuality(String quality) {
    _quality = quality;
    _box.put('quality', _quality);
    notifyListeners();
  }

  void updateStorageUsed(double bytes) {
    _storageUsed = bytes;
    _box.put('storageUsed', _storageUsed);
    notifyListeners();
  }

  Future<void> clearCache() async {
    _storageUsed = 0;
    _box.put('storageUsed', 0.0);
    notifyListeners();
  }

  int get qualityValue {
    switch (_quality) {
      case 'Low':
        return 50;
      case 'Medium':
        return 75;
      case 'High':
        return 100;
      default:
        return 75;
    }
  }
}
