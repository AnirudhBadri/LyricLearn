import 'package:flutter/foundation.dart';
import '../models/song_models.dart';
import '../services/gemini_service.dart';
import '../services/db_service.dart';

/// The navigation steps in the app, mirroring the web app's AppStep.
enum AppStep { searchInput, chooseFilm, chooseSong, showLyrics }

/// Search mode toggle.
enum SearchType { lyrics, film }

/// Central app state provider — replaces the React useState hooks in App.tsx.
class AppProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final DbService _db = DbService();

  // ── State fields ─────────────────────────────────────────────
  AppStep _appStep = AppStep.searchInput;
  SearchType _searchType = SearchType.lyrics;

  String _searchInput = '';
  List<FilmInfo> _filmMatches = [];
  List<SongData> _songMatches = [];
  SongData? _selectedSong;

  String _originalLyrics = '';
  String _interleavedLyrics = '';
  String _transliteratedLyrics = '';
  String _translation = '';
  String _translatedInterleavedLyrics = '';

  bool _isLoading = false;
  String _loadingMessage = '';
  String _error = '';
  bool _detailedDiction = false;

  // ── Getters ─────────────────────────────────────────────────
  AppStep get appStep => _appStep;
  SearchType get searchType => _searchType;
  String get searchInput => _searchInput;
  List<FilmInfo> get filmMatches => _filmMatches;
  List<SongData> get songMatches => _songMatches;
  SongData? get selectedSong => _selectedSong;

  String get originalLyrics => _originalLyrics;
  String get interleavedLyrics => _interleavedLyrics;
  String get transliteratedLyrics => _transliteratedLyrics;
  String get translation => _translation;
  String get translatedInterleavedLyrics => _translatedInterleavedLyrics;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String get error => _error;
  bool get detailedDiction => _detailedDiction;

  bool get isLyricsSearchInvalid =>
      _searchType == SearchType.lyrics &&
      _searchInput.trim().isNotEmpty &&
      _searchInput.trim().split(RegExp(r'\s+')).length < 2;

  bool get isSearchDisabled =>
      _searchInput.trim().isEmpty || isLyricsSearchInvalid;

  // ── Setters ─────────────────────────────────────────────────
  void setSearchInput(String value) {
    _searchInput = value;
    notifyListeners();
  }

  void setSearchType(SearchType type) {
    _searchType = type;
    notifyListeners();
  }

  void setDetailedDiction(bool value) {
    _detailedDiction = value;
    notifyListeners();
    // Re-generate transliteration if one already exists
    if (_transliteratedLyrics.isNotEmpty) {
      _regenerateTransliteration();
    }
  }

  // ── Initialization ─────────────────────────────────────────
  Future<void> initDatabase() async {
    final count = await _db.countSongs();
    if (count == 0) {
      await _db.preseedDatabase();
    }
  }

  // ── Search ─────────────────────────────────────────────────
  Future<void> handleSearch() async {
    if (isSearchDisabled || _isLoading) return;
    _error = '';
    _isLoading = true;
    _songMatches = [];
    _filmMatches = [];
    notifyListeners();

    try {
      if (_searchType == SearchType.lyrics) {
        _loadingMessage = 'Searching for songs...';
        notifyListeners();
        final results = await _gemini.getSongInfoFromLyrics(_searchInput);
        if (results.isEmpty) {
          _error =
              'No songs found starting with those lyrics. Please check your spelling or try again.';
        } else {
          _songMatches = results.map((s) => SongData.fromSongInfo(s)).toList();
          _appStep = AppStep.chooseSong;
        }
      } else {
        _loadingMessage = 'Searching for films...';
        notifyListeners();
        final results = await _gemini.getFilmsByName(_searchInput);
        if (results.isEmpty) {
          _error =
              'No films found starting with that name. Please check the film title and try again.';
        } else {
          _filmMatches = results;
          _appStep = AppStep.chooseFilm;
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Film selection ─────────────────────────────────────────
  Future<void> handleSelectFilm(FilmInfo film) async {
    _isLoading = true;
    _loadingMessage = 'Finding songs for ${film.film}...';
    _error = '';
    _songMatches = [];
    notifyListeners();

    try {
      final results = await _gemini.getSongsFromFilm(film.film);
      if (results.isEmpty) {
        _error =
            'No songs found for ${film.film}. You can go back and try another film.';
      } else {
        _songMatches = results.map((s) => SongData.fromSongInfo(s)).toList();
      }
      _appStep = AppStep.chooseSong;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Song selection + lyrics fetch ──────────────────────────
  Future<void> handleSelectSong(SongData song) async {
    _isLoading = true;
    _loadingMessage = 'Fetching lyrics...';
    _error = '';
    _selectedSong = song;
    _interleavedLyrics = '';
    _transliteratedLyrics = '';
    _translation = '';
    _translatedInterleavedLyrics = '';
    notifyListeners();

    try {
      // Check cache first
      final stored = await _db.getSongByTitleAndArtist(song.title, song.artist);
      if (stored != null &&
          stored.originalLyrics != null &&
          stored.originalLyrics!.isNotEmpty) {
        _originalLyrics = stored.originalLyrics!;
        _selectedSong = stored;
      } else {
        final lyrics = await _gemini.getOriginalLyrics(song);
        _originalLyrics = lyrics;

        final songToSave = song.copyWithData(
          id: stored?.id,
          originalLyrics: lyrics,
        );
        final saved = await _db.saveSong(songToSave);
        _selectedSong = saved;
      }
      _appStep = AppStep.showLyrics;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _appStep = AppStep.showLyrics;
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Transliteration ────────────────────────────────────────
  Future<void> handleGetTransliteration() async {
    if (_selectedSong == null || _originalLyrics.isEmpty) return;
    _isLoading = true;
    _loadingMessage = 'Transliterating to English...';
    _error = '';
    notifyListeners();

    try {
      final transliterated = await _gemini.generateTransliteration(
        _originalLyrics,
        _selectedSong!.language ?? 'the original language',
        detailed: _detailedDiction,
      );
      _transliteratedLyrics = transliterated;
      _interleavedLyrics = _buildInterleaved(_originalLyrics, transliterated);
      _translation = '';
      _translatedInterleavedLyrics = '';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  /// Re-generate transliteration when detailed diction is toggled.
  Future<void> _regenerateTransliteration() async {
    await handleGetTransliteration();
  }

  // ── Translation ────────────────────────────────────────────
  Future<void> handleGetTranslation() async {
    if (_selectedSong == null ||
        _originalLyrics.isEmpty ||
        _transliteratedLyrics.isEmpty) {
      return;
    }
    _isLoading = true;
    _loadingMessage = 'Translating to English...';
    _error = '';
    notifyListeners();

    try {
      final translated = await _gemini.generateTranslation(
        _originalLyrics,
        _transliteratedLyrics,
        _selectedSong!.language ?? 'the original language',
      );
      _translation = translated;
      _translatedInterleavedLyrics = _buildTranslatedInterleaved(
        _transliteratedLyrics,
        translated,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _loadingMessage = '';
      notifyListeners();
    }
  }

  // ── Navigation ─────────────────────────────────────────────
  void goBack() {
    switch (_appStep) {
      case AppStep.chooseFilm:
        resetSearch();
        break;
      case AppStep.chooseSong:
        if (_filmMatches.isNotEmpty) {
          _appStep = AppStep.chooseFilm;
        } else {
          resetSearch();
        }
        break;
      case AppStep.showLyrics:
        if (_songMatches.isNotEmpty) {
          _appStep = AppStep.chooseSong;
        } else {
          resetSearch();
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void resetSearch() {
    _searchInput = '';
    _error = '';
    _filmMatches = [];
    _songMatches = [];
    _selectedSong = null;
    _originalLyrics = '';
    _interleavedLyrics = '';
    _transliteratedLyrics = '';
    _translation = '';
    _translatedInterleavedLyrics = '';
    _appStep = AppStep.searchInput;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────

  /// Build interleaved view: original + transliteration alternating.
  String _buildInterleaved(String original, String transliterated) {
    final originalLines = original.split('\n');
    final transliteratedLines = transliterated.split('\n');
    final buffer = StringBuffer();
    final maxLines = originalLines.length > transliteratedLines.length
        ? originalLines.length
        : transliteratedLines.length;

    for (int i = 0; i < maxLines; i++) {
      final ol = i < originalLines.length ? originalLines[i] : '';
      final tl = i < transliteratedLines.length ? transliteratedLines[i] : '';

      if (ol.trim().isEmpty && tl.trim().isEmpty) {
        buffer.writeln();
      } else {
        if (ol.trim().isNotEmpty) buffer.writeln(ol);
        if (tl.trim().isNotEmpty) {
          buffer.writeln(tl);
          buffer.writeln();
        } else {
          buffer.writeln();
        }
      }
    }
    return buffer.toString().trim();
  }

  /// Build translated interleaved: transliteration + (translation) alternating.
  String _buildTranslatedInterleaved(String transliterated, String translated) {
    final transliteratedLines = transliterated.split('\n');
    final translationLines = translated.split('\n');
    final buffer = StringBuffer();
    final maxLines = transliteratedLines.length > translationLines.length
        ? transliteratedLines.length
        : translationLines.length;

    for (int i = 0; i < maxLines; i++) {
      final tlitLine =
          i < transliteratedLines.length ? transliteratedLines[i] : '';
      final tranLine = i < translationLines.length ? translationLines[i] : '';

      if (tlitLine.trim().isEmpty && tranLine.trim().isEmpty) {
        buffer.writeln();
      } else if (tlitLine.trim().isNotEmpty) {
        buffer.writeln(tlitLine);
        if (tranLine.trim().isNotEmpty) {
          buffer.writeln('($tranLine)');
          buffer.writeln();
        } else {
          buffer.writeln();
        }
      }
    }
    return buffer.toString().trim();
  }

  /// Generate the metadata header for exports/copies.
  String generateFileHeader() {
    if (_selectedSong == null) return '';
    final song = _selectedSong!;
    final parts = <String>['Title: ${song.title}', 'Artist(s): ${song.artist}'];

    if (song.film != null) {
      String filmLine = 'Film: ${song.film}';
      if (song.year != null) filmLine += ' (${song.year})';
      if (song.language != null) filmLine += ' - ${song.language}';
      parts.add(filmLine);
    } else {
      if (song.year != null) parts.add('Year: ${song.year}');
      if (song.language != null) parts.add('Language: ${song.language}');
    }

    if (song.composer != null) parts.add('Composer: ${song.composer}');
    if (song.lyricist != null) parts.add('Lyricist: ${song.lyricist}');
    if (song.scale != null) parts.add('Scale: ${song.scale}');
    if (song.raga != null) parts.add('Raga: ${song.raga}');

    final separator = '=' * 40;
    return '$separator\n${parts.join('\n')}\n$separator\n\n';
  }

  /// Generate side-by-side content for export.
  String generateSideBySideContent() {
    if (_transliteratedLyrics.isEmpty || _translation.isEmpty) return '';

    final transliteratedLines = _transliteratedLyrics.split('\n');
    final translationLines = _translation.split('\n');
    final maxLength = transliteratedLines.fold<int>(
      0,
      (max, line) => line.length > max ? line.length : max,
    );
    final maxLines = transliteratedLines.length > translationLines.length
        ? transliteratedLines.length
        : translationLines.length;

    final buffer = StringBuffer();
    for (int i = 0; i < maxLines; i++) {
      final tlitLine =
          i < transliteratedLines.length ? transliteratedLines[i] : '';
      final tranLine = i < translationLines.length ? translationLines[i] : '';

      if (tlitLine.trim().isEmpty && tranLine.trim().isEmpty) {
        buffer.writeln();
      } else {
        buffer.writeln('${tlitLine.padRight(maxLength)} | $tranLine');
      }
    }
    return buffer.toString().trim();
  }
}
