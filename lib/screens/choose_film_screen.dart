import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ChooseFilmScreen extends StatelessWidget {
  const ChooseFilmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final films = provider.filmMatches;

        return Column(
          children: [
            // ── Toolbar ──
            _buildToolbar(context, provider, films.length),
            const Divider(),

            // ── Film list ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: films.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final film = films[index];
                  return _FilmCard(
                    film: film,
                    onTap: () => provider.handleSelectFilm(film),
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: provider.resetSearch,
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Back to search',
          ),
          const SizedBox(width: 8),
          Text(
            '$count Film${count != 1 ? 's' : ''} Found',
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
}

class _FilmCard extends StatelessWidget {
  final dynamic film; // FilmInfo
  final VoidCallback onTap;

  const _FilmCard({required this.film, required this.onTap});

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
                film.film,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${film.year} - ${film.language}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
