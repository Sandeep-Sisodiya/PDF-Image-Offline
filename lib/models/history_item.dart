import 'package:hive/hive.dart';

part 'history_item.g.dart';

@HiveType(typeId: 0)
class HistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final String operationType; // IMG_TO_PDF, PDF_TO_IMG, COMPRESS_IMG, COMPRESS_PDF

  @HiveField(4)
  final String fileSize;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String fileType; // pdf, jpg, png

  HistoryItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.operationType,
    required this.fileSize,
    required this.createdAt,
    required this.fileType,
  });

  String get operationLabel {
    switch (operationType) {
      case 'IMG_TO_PDF':
        return 'IMG → PDF';
      case 'PDF_TO_IMG':
        return 'PDF → IMG';
      case 'COMPRESS_IMG':
        return 'COMPRESS';
      case 'COMPRESS_PDF':
        return 'COMPRESS';
      default:
        return operationType;
    }
  }

  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'webp'].contains(fileType.toLowerCase());
}
