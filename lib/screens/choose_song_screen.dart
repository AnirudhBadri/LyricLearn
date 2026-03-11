import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ChooseSongScreen extends StatelessWidget {
  const ChooseSongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final songs = provider.songMatches;
        final hasFilms = provider.filmMatches.isNotEmpty;

        return Column(
          children: [
            // ── Toolbar ──
            _buildToolbar(context, provider, songs.length, hasFilms),
            const Divider(),

            // ── Song list or empty state ──
            Expanded(
              child: songs.isEmpty
                  ? _buildEmptyState(provider)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: songs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return _SongCard(
                          song: song,
                          onTap: () => provider.handleSelectSong(song),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppProvider provider,
    int count,
    bool hasFilms,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: provider.goBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            count > 0
                ? '$count Song${count != 1 ? 's' : ''} Found'
                : 'No Songs Found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, size: 64, color: AppColors.textDim),
          const SizedBox(height: 16),
          const Text(
            'No songs were found for the selected film.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          if (provider.error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              provider.error,
              style: const TextStyle(color: AppColors.errorText),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final dynamic song; // SongData
  final VoidCallback onTap;

  const _SongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              if (song.film != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${song.film}${song.year != null ? ' (${song.year})' : ''}${song.language != null ? ' - ${song.language}' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
