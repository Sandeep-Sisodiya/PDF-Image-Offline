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
  String _searchQuery = '';

  List<HistoryItem> get items {
    List<HistoryItem> filtered = _items;

    // Apply type filter
    if (_filterType == 'pdf') {
      filtered = filtered.where((item) => item.isPdf).toList();
    } else if (_filterType == 'image') {
      filtered = filtered.where((item) => item.isImage).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((item) => item.fileName.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  List<HistoryItem> get allItems => _items;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;

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

  void setSearchQuery(String query) {
    _searchQuery = query;
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

  /// Deletes the history item AND the associated file from storage.
  Future<void> deleteItemWithFile(String id) async {
    // Find the item first to get the file path
    final item = _items.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('Item not found'),
    );

    // Delete the actual file from storage
    try {
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // File might already be deleted or inaccessible, continue with removing from history
    }

    // Delete from Hive
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
