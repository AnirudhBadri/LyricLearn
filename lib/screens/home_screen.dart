import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'choose_film_screen.dart';
import 'choose_song_screen.dart';
import 'lyrics_screen.dart';

/// Root screen that switches views based on the current AppStep,
/// mirroring the web app's single-page state-based navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──
                _buildHeader(context),
                const Divider(),
                // ── Content ──
                Expanded(
                  child: Stack(
                    children: [
                      _buildContent(provider),
                      if (provider.isLoading) _buildLoadingOverlay(provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.purplePinkGradient.createShader(bounds),
            child: const Text(
              'LyricLearn',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Learn and Understand Non-English Songs',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppProvider provider) {
    switch (provider.appStep) {
      case AppStep.searchInput:
        return const SearchScreen();
      case AppStep.chooseFilm:
        return const ChooseFilmScreen();
      case AppStep.chooseSong:
        return const ChooseSongScreen();
      case AppStep.showLyrics:
        return const LyricsScreen();
    }
  }

  Widget _buildLoadingOverlay(AppProvider provider) {
    return Container(
      color: AppColors.bg.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.purple500,
                ),
              ),
            ),
            if (provider.loadingMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                provider.loadingMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
