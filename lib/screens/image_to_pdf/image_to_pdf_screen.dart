import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../models/history_item.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isConverting = false;
  String _pageSize = 'A4 (Auto-fit)';
  String _margins = 'No Margins';
  int? _selectedIndex;

  double get _estimatedSize {
    double total = 0;
    for (var img in _selectedImages) {
      total += img.lengthSync();
    }
    return total / (1024 * 1024); // Convert to MB
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: context.read<SettingsProvider>().qualityValue,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedIndex = null;
    });
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
      _selectedIndex = null;
    });
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isConverting = true);

    try {
      final pdf = pw.Document();

      for (var imageFile in _selectedImages) {
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: _margins == 'No Margins'
                ? const pw.EdgeInsets.all(0)
                : const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDir.path}/documaster_output');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${outputDir.path}/converted_$timestamp.pdf');
      await outputFile.writeAsBytes(await pdf.save());

      // Save to public storage
      final fileName = 'converted_$timestamp.pdf';
      String publicPath = outputFile.path;
      try {
        publicPath = await FileSaverHelper.saveToPublicStorage(
          sourcePath: outputFile.path,
          fileName: fileName,
          isImage: false,
        );
      } catch (_) {}

      final fileSize = await outputFile.length();
      final fileSizeStr = _formatFileSize(fileSize);

      final historyItem = HistoryItem(
        id: const Uuid().v4(),
        fileName: fileName,
        filePath: outputFile.path,
        operationType: 'IMG_TO_PDF',
        fileSize: fileSizeStr,
        createdAt: DateTime.now(),
        fileType: 'pdf',
      );

      if (mounted) {
        await context.read<HistoryProvider>().addItem(historyItem);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF created successfully! ($fileSizeStr)'),
            backgroundColor: AppTheme.primaryIndigoLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkNavy,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadArea(),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSelectedImagesSection(),
                    const SizedBox(height: 28),
                    _buildPdfSettings(),
                  ],
                ],
              ),
            ),
          ),
          // Bottom Action
          if (_selectedImages.isNotEmpty) _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 8, 4, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Image to PDF',
                  style: GoogleFonts.publicSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryIndigoLight.withValues(alpha: 0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: AppTheme.primaryIndigoLight.withValues(alpha: 0.05),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppTheme.primaryIndigoLight.withValues(alpha: 0.4),
            borderRadius: 20,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryIndigoLight.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.add_photo_alternate,
                  size: 36,
                  color: AppTheme.primaryIndigoLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Images',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PNG, JPG, HEIC up to 20MB each',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigoLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryIndigoLight.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Browse Gallery',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECTED IMAGES (${_selectedImages.length})',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: _clearAll,
              child: Text(
                'Clear all',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: AppTheme.primaryIndigoLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return _buildAddMoreButton();
            }
            return _buildImageThumbnail(index);
          },
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = isSelected ? null : index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppTheme.primaryIndigoLight, width: 2)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
                opacity: isSelected ? const AlwaysStoppedAnimation(0.6) : null,
              ),
              if (isSelected)
                const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryIndigoLight,
                    size: 28,
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1E293B),
            width: 2,
          ),
          color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppTheme.textTertiary, size: 24),
            const SizedBox(height: 4),
            Text(
              'ADD MORE',
              style: GoogleFonts.publicSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF SETTINGS',
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Page Size
        _buildSettingTile(
          icon: Icons.description,
          title: 'Page Size',
          value: _pageSize,
          iconBgColor: AppTheme.primaryIndigoLight.withValues(alpha: 0.2),
          iconColor: AppTheme.primaryIndigoLight,
          onTap: () => _showPageSizeDialog(),
        ),
        const SizedBox(height: 12),
        // Margins
        _buildSettingTile(
          icon: Icons.border_outer,
          title: 'Margins',
          value: _margins,
          iconBgColor: const Color(0xFF1E293B),
          iconColor: AppTheme.textSecondary,
          trailing: Text(
            'Edit',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryIndigoLight,
            ),
          ),
          onTap: () => _showMarginsDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBgColor,
    required Color iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[trailing, const SizedBox(width: 4)],
                const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      'Estimated size: ',
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${_estimatedSize.toStringAsFixed(1)} MB',
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isConverting ? null : _convertToPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigoLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 16,
                    shadowColor: AppTheme.primaryIndigoLight.withValues(alpha: 0.4),
                  ),
                  child: _isConverting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Convert to PDF',
                              style: GoogleFonts.publicSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPageSizeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page Size',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            for (var size in ['A4 (Auto-fit)', 'Letter', 'A3', 'A5'])
              ListTile(
                title: Text(size, style: const TextStyle(color: Colors.white)),
                trailing: _pageSize == size
                    ? const Icon(Icons.check, color: AppTheme.primaryIndigoLight)
                    : null,
                onTap: () {
                  setState(() => _pageSize = size);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMarginsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Margins',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            for (var margin in ['No Margins', 'Small', 'Medium', 'Large'])
              ListTile(
                title: Text(margin, style: const TextStyle(color: Colors.white)),
                trailing: _margins == margin
                    ? const Icon(Icons.check, color: AppTheme.primaryIndigoLight)
                    : null,
                onTap: () {
                  setState(() => _margins = margin);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // The container already has a border, so this is decorative only
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
