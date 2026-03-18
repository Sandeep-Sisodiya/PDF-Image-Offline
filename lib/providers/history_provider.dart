import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  static const String _boxName = 'history';
  late Box<HistoryItem> _box;
  List<HistoryItem> _items = [];
  String _filterType = 'all'; // all, pdf, image

  List<HistoryItem> get items {
    if (_filterType == 'pdf') {
      return _items.where((item) => item.isPdf).toList();
    } else if (_filterType == 'image') {
      return _items.where((item) => item.isImage).toList();
    }
    return _items;
  }

  List<HistoryItem> get allItems => _items;
  String get filterType => _filterType;

  Future<void> init() async {
    _box = await Hive.openBox<HistoryItem>(_boxName);
    _loadItems();
  }

  void _loadItems() {
    _items = _box.values.toList();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> addItem(HistoryItem item) async {
    await _box.put(item.id, item);
    _loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    _loadItems();
  }

  Future<void> clearAll() async {
    await _box.clear();
    _loadItems();
  }

  Future<double> calculateStorageUsed() async {
    double totalSize = 0;
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${appDir.path}/documaster_output');
    if (await outputDir.exists()) {
      await for (var entity in outputDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    return totalSize;
  }

  // Group items by date for section headers
  Map<String, List<HistoryItem>> get groupedItems {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final Map<String, List<HistoryItem>> grouped = {};

    for (var item in items) {
      String key;
      if (item.createdAt.isAfter(thisMonth)) {
        key = 'This Month';
      } else if (item.createdAt.isAfter(lastMonth)) {
        key = 'Last Month';
      } else {
        key = 'Older';
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    return grouped;
  }
}
