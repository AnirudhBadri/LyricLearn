import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/export_helper.dart';

/// A single lyrics panel with title, copy & share buttons, and scrollable text.
/// Mirrors one of the web app's gray-800 panels in the lyrics grid.
class LyricsPanel extends StatefulWidget {
  final String title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final String content;
  final String? exportContent; // content with header for copy/download
  final String? exportFilename;
  final Widget? headerTrailing; // e.g. the "Detailed Diction" toggle
  final Widget? customBody; // override the default pre-formatted text

  const LyricsPanel({
    super.key,
    required this.title,
    this.titleIcon,
    this.titleIconColor,
    required this.content,
    this.exportContent,
    this.exportFilename,
    this.headerTrailing,
    this.customBody,
  });

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    final text = widget.exportContent ?? widget.content;
    if (text.isEmpty) return;
    await ExportHelper.copyToClipboard(text);
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _handleShare() async {
    final text = widget.exportContent ?? widget.content;
    if (text.isEmpty) return;
    if (widget.exportFilename != null) {
      await ExportHelper.shareAsFile(text, widget.exportFilename!);
    } else {
      await ExportHelper.shareText(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              if (widget.titleIcon != null) ...[
                Icon(
                  widget.titleIcon,
                  size: 20,
                  color: widget.titleIconColor ?? AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // Copy button
              _iconButton(
                icon: _copied ? Icons.check : Icons.copy,
                color: _copied ? AppColors.success : AppColors.textSecondary,
                tooltip: 'Copy',
                onTap: _handleCopy,
              ),
              const SizedBox(width: 4),
              // Share / download button
              _iconButton(
                icon: Icons.share,
                color: AppColors.textSecondary,
                tooltip: 'Share',
                onTap: _handleShare,
              ),
            ],
          ),
          if (widget.headerTrailing != null) ...[
            const SizedBox(height: 8),
            widget.headerTrailing!,
          ],
          const SizedBox(height: 10),

          // ── Body ──
          Expanded(
            child: widget.customBody ??
                SingleChildScrollView(
                  child: SelectableText(
                    widget.content,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceHover,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
