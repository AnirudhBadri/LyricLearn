import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_button.dart';
import '../widgets/lyrics_panel.dart';

/// The main lyrics dashboard. Shows up to 5 lyrics panels in a
/// vertically scrollable list (mobile-first), plus action buttons at
/// the bottom matching the web app's SHOW_LYRICS step.
class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final song = provider.selectedSong;
        if (song == null) return const SizedBox.shrink();

        final hasOriginal =
            provider.originalLyrics.isNotEmpty && provider.error.isEmpty;
        final hasInterleaved =
            provider.interleavedLyrics.isNotEmpty && provider.error.isEmpty;
        final hasTransliterated =
            provider.transliteratedLyrics.isNotEmpty && provider.error.isEmpty;
        final hasTranslatedInterleaved =
            provider.translatedInterleavedLyrics.isNotEmpty &&
                provider.error.isEmpty;
        final hasSideBySide = provider.transliteratedLyrics.isNotEmpty &&
            provider.translation.isNotEmpty &&
            provider.error.isEmpty;

        final fileHeader = provider.generateFileHeader();
        final safeTitle = song.title.replaceAll(RegExp(r'\s+'), '_');

        return Column(
          children: [
            // ── Toolbar with song info ──
            _buildToolbar(context, provider, song),
            const Divider(),

            // ── Panels ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (hasOriginal)
                    _panelWrapper(
                      LyricsPanel(
                        title:
                            'Original Lyrics (${song.language ?? "Original"})',
                        content: provider.originalLyrics,
                        exportContent: fileHeader + provider.originalLyrics,
                        exportFilename: '${safeTitle}_originallyrics.txt',
                      ),
                    ),
                  if (hasInterleaved)
                    _panelWrapper(
                      LyricsPanel(
                        title: 'Interleaved View (Learn)',
                        titleIcon: Icons.view_list,
                        titleIconColor: AppColors.teal300,
                        content: provider.interleavedLyrics,
                        exportContent: fileHeader + provider.interleavedLyrics,
                        exportFilename: '${safeTitle}_interleaved.txt',
                      ),
                    ),
                  if (hasTransliterated)
                    _panelWrapper(
                      LyricsPanel(
                        title: 'Transliteration (Sing-Along)',
                        titleIcon: Icons.translate,
                        titleIconColor: AppColors.blue300,
                        content: provider.transliteratedLyrics,
                        exportContent:
                            fileHeader + provider.transliteratedLyrics,
                        exportFilename: '${safeTitle}_transliteration.txt',
                        headerTrailing:
                            _buildDetailedDictionToggle(context, provider),
                      ),
                    ),
                  if (hasTranslatedInterleaved)
                    _panelWrapper(
                      LyricsPanel(
                        title: 'Translation (Line-by-Line)',
                        titleIcon: Icons.auto_awesome,
                        titleIconColor: AppColors.yellow300,
                        content: provider.translatedInterleavedLyrics,
                        exportContent:
                            fileHeader + provider.translatedInterleavedLyrics,
                        exportFilename: '${safeTitle}_englishlyrics.txt',
                      ),
                    ),
                  if (hasSideBySide)
                    _panelWrapper(
                      _SideBySidePanel(
                        transliterated: provider.transliteratedLyrics,
                        translation: provider.translation,
                        exportContent:
                            fileHeader + provider.generateSideBySideContent(),
                        exportFilename:
                            '${safeTitle}_englishlyrics_side-by-side.txt',
                      ),
                    ),
                ],
              ),
            ),

            // ── Error ──
            if (provider.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ErrorBanner(message: provider.error),
              ),

            // ── Action buttons ──
            _buildActionBar(context, provider),
          ],
        );
      },
    );
  }

  Widget _panelWrapper(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(height: 350, child: child),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppProvider provider,
    dynamic song,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: provider.goBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Back to song selection',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedDictionToggle(
    BuildContext context,
    AppProvider provider,
  ) {
    return GestureDetector(
      onTap: () => provider.setDetailedDiction(!provider.detailedDiction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: provider.detailedDiction
              ? AppColors.teal500
              : AppColors.surfaceHover,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.record_voice_over,
              size: 14,
              color: provider.detailedDiction
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Detailed Diction',
              style: TextStyle(
                fontSize: 12,
                color: provider.detailedDiction
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppProvider provider) {
    final showTransliterate = provider.transliteratedLyrics.isEmpty &&
        provider.originalLyrics.isNotEmpty &&
        provider.error.isEmpty;
    final showTranslate = provider.transliteratedLyrics.isNotEmpty &&
        provider.translation.isEmpty &&
        provider.error.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (showTransliterate)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: provider.handleGetTransliteration,
                  gradient: AppColors.blueIndigoGradient,
                  child: const Text('Transliterate to English'),
                ),
              ),
            ),
          if (showTranslate)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: provider.handleGetTranslation,
                  gradient: AppColors.greenTealGradient,
                  child: const Text('Translate to English'),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.resetSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceHover,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Start a New Search',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side panel with synchronized scroll between
/// transliteration (left) and translation (right).
class _SideBySidePanel extends StatefulWidget {
  final String transliterated;
  final String translation;
  final String exportContent;
  final String exportFilename;

  const _SideBySidePanel({
    required this.transliterated,
    required this.translation,
    required this.exportContent,
    required this.exportFilename,
  });

  @override
  State<_SideBySidePanel> createState() => _SideBySidePanelState();
}

class _SideBySidePanelState extends State<_SideBySidePanel> {
  final _leftController = ScrollController();
  final _rightController = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _leftController
        .addListener(() => _syncScroll(_leftController, _rightController));
    _rightController
        .addListener(() => _syncScroll(_rightController, _leftController));
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (_isSyncing) return;
    _isSyncing = true;
    if (target.hasClients) {
      target.jumpTo(source.offset);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isSyncing = false;
    });
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LyricsPanel(
      title: 'Translation (Side-by-Side)',
      titleIcon: Icons.view_column,
      titleIconColor: AppColors.indigo300,
      content: widget.exportContent,
      exportContent: widget.exportContent,
      exportFilename: widget.exportFilename,
      customBody: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Transliteration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transliteration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _leftController,
                    child: SelectableText(
                      widget.transliterated,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right column - Translation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _rightController,
                    child: SelectableText(
                      widget.translation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
