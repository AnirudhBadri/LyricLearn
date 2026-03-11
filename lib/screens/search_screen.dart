import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Keep controller in sync if provider resets searchInput
        if (_controller.text != provider.searchInput) {
          _controller.text = provider.searchInput;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }

        final isLyrics = provider.searchType == SearchType.lyrics;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Search type toggle ──
                  _buildSearchTypeToggle(provider),
                  const SizedBox(height: 20),

                  // ── Subtitle ──
                  Text(
                    isLyrics
                        ? 'Start by entering the first few words of a song.'
                        : 'Enter a film name to find matching movies.',
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // ── Search field ──
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (v) => provider.setSearchInput(v),
                    onSubmitted: (_) => provider.handleSearch(),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        isLyrics ? Icons.music_note : Icons.movie_outlined,
                        color: AppColors.textDim,
                      ),
                      hintText:
                          isLyrics ? 'e.g., Nilaave Vaa...' : 'e.g., Mouna...',
                    ),
                  ),

                  // ── Validation warning ──
                  if (provider.isLyricsSearchInvalid) ...[
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please enter at least the first two words of the song to get reliable search results',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Search button ──
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: provider.isSearchDisabled
                          ? null
                          : provider.handleSearch,
                      gradient: AppColors.purplePinkGradient,
                      child: Text(
                        isLyrics ? 'Search Lyrics' : 'Search Film',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // ── Error ──
                  if (provider.error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(message: provider.error),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTypeToggle(AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _toggleButton(
            label: 'Search by Lyrics',
            isActive: provider.searchType == SearchType.lyrics,
            onTap: () => provider.setSearchType(SearchType.lyrics),
          ),
          _toggleButton(
            label: 'Search by Film',
            isActive: provider.searchType == SearchType.film,
            onTap: () => provider.setSearchType(SearchType.film),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.purple600 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
