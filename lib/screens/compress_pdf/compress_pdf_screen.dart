import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../../core/theme/app_theme.dart';
import '../../models/history_item.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  File? _selectedPdf;
  String? _pdfName;
  bool _isCompressing = false;
  double _compressionQuality = 0.6;
  double _progress = 0;
  Map<String, dynamic>? _result;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _pdfName = result.files.single.name;
        _result = null;
      });
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedPdf == null) return;

    setState(() {
      _isCompressing = true;
      _progress = 0;
      _result = null;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDir.path}/documaster_output');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final originalSize = _selectedPdf!.lengthSync();
      final quality = (_compressionQuality * 100).toInt();
      final dpi = quality >= 80 ? 200.0 : (quality >= 50 ? 150.0 : 100.0);

      // Rasterize pages, then re-create PDF with compressed images
      final newPdf = pw.Document();
      int pageCount = 0;

      final pages = <pw.MemoryImage>[];
      await for (var page in Printing.raster(_selectedPdf!.readAsBytesSync(), dpi: dpi)) {
        final pngBytes = await page.toPng();
        final decoded = img.decodePng(pngBytes);
        if (decoded != null) {
          final compressed = img.encodeJpg(decoded, quality: quality);
          pages.add(pw.MemoryImage(compressed));
        }
        pageCount++;
        setState(() {
          _progress = pageCount / (pageCount + 1);
        });
      }

      for (var pageImage in pages) {
        newPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(0),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pageImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${outputDir.path}/compressed_$timestamp.pdf');
      await outputFile.writeAsBytes(await newPdf.save());

      final compressedSize = await outputFile.length();
      final savings = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      _result = {
        'original': _formatFileSize(originalSize),
        'compressed': _formatFileSize(compressedSize),
        'savings': '$savings%',
        'file': outputFile,
      };

      final historyItem = HistoryItem(
        id: const Uuid().v4(),
        fileName: 'compressed_$timestamp.pdf',
        filePath: outputFile.path,
        operationType: 'COMPRESS_PDF',
        fileSize: _formatFileSize(compressedSize),
        createdAt: DateTime.now(),
        fileType: 'pdf',
      );

      if (mounted) {
        await context.read<HistoryProvider>().addItem(historyItem);
        setState(() => _progress = 1.0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF compressed! Saved $savings%'),
            backgroundColor: AppTheme.accentCyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkNavy,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadArea(),
                  if (_selectedPdf != null) ...[
                    const SizedBox(height: 24),
                    _buildSelectedFile(),
                    const SizedBox(height: 24),
                    _buildQualitySlider(),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _buildResult(),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedPdf != null && _result == null) _buildBottomAction(),
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
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                  'Compress PDF',
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
      onTap: _pickPdf,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentCyan.withValues(alpha: 0.4),
            width: 2,
          ),
          color: AppTheme.accentCyan.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCyan.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.compress,
                size: 36,
                color: AppTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select PDF',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a PDF file to compress',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Browse Files',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.accentCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pdfName ?? 'Unknown',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(_selectedPdf!.lengthSync()),
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _selectedPdf = null;
                _pdfName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compression Level',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(_compressionQuality * 100).toInt()}%',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accentCyan,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppTheme.accentCyan,
              overlayColor: AppTheme.accentCyan.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _compressionQuality,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) => setState(() => _compressionQuality = value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Smaller file', style: GoogleFonts.publicSans(fontSize: 11, color: AppTheme.textSecondary)),
              Text('Better quality', style: GoogleFonts.publicSans(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            'Compression Complete!',
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Original', _result!['original']),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildStatColumn('Compressed', _result!['compressed']),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildStatColumn('Saved', _result!['savings']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.publicSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
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
              if (_isCompressing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompressing ? null : _compressPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 16,
                    shadowColor: AppTheme.accentCyan.withValues(alpha: 0.4),
                  ),
                  child: _isCompressing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.compress, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Compress PDF',
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
}
