import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/history_item.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkBrown,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<HistoryProvider>(
              builder: (context, provider, child) {
                if (provider.items.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildHistoryList(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarkBrown.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_edu,
                    color: AppTheme.primaryOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'History',
                    style: GoogleFonts.publicSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.search, color: Colors.grey[500]),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tabs
          Consumer<HistoryProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  _FilterTab(
                    label: 'All Files',
                    isActive: provider.filterType == 'all',
                    onTap: () => provider.setFilter('all'),
                  ),
                  const SizedBox(width: 24),
                  _FilterTab(
                    label: 'PDFs',
                    isActive: provider.filterType == 'pdf',
                    onTap: () => provider.setFilter('pdf'),
                  ),
                  const SizedBox(width: 24),
                  _FilterTab(
                    label: 'Images',
                    isActive: provider.filterType == 'image',
                    onTap: () => provider.setFilter('image'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No files yet',
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your converted and compressed files\nwill appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, HistoryProvider provider) {
    final grouped = provider.groupedItems;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.entries.fold<int>(0, (sum, entry) => sum + 1 + entry.value.length),
      itemBuilder: (context, index) {
        int currentIndex = 0;
        for (var entry in grouped.entries) {
          // Section header
          if (index == currentIndex) {
            return Padding(
              padding: EdgeInsets.only(
                top: currentIndex == 0 ? 0 : 20,
                bottom: 12,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: GoogleFonts.publicSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                  letterSpacing: 2,
                ),
              ),
            );
          }
          currentIndex++;

          // Items
          for (int i = 0; i < entry.value.length; i++) {
            if (index == currentIndex) {
              return _HistoryItemCard(
                item: entry.value[i],
                onDelete: () => provider.deleteItem(entry.value[i].id),
              );
            }
            currentIndex++;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.primaryOrange : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onDelete;

  const _HistoryItemCard({
    required this.item,
    required this.onDelete,
  });

  IconData _getIcon() {
    if (item.isPdf) return Icons.picture_as_pdf;
    if (item.isImage) return Icons.image;
    return Icons.description;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIcon(), color: AppTheme.primaryOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.operationLabel,
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.fileSize,
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt),
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final file = File(item.filePath);
                    if (file.existsSync()) {
                      OpenFile.open(item.filePath);
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(
                    'Download',
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.shareXFiles([XFile(item.filePath)]);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(
                    'Share',
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
