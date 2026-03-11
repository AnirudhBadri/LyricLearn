import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/song_models.dart';

class GeminiService {
  static const String _model = 'gemini-2.5-flash';
  static const int _maxRetries = 3;

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'GEMINI_API_KEY not set. Please add it to your .env file.',
      );
    }
    return key;
  }

  /// Low-level Gemini API call using HTTP (mirrors generateContentFetch).
  Future<String> _generateContent(
    String prompt, {
    bool useGoogleSearch = false,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final payload = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    };

    if (useGoogleSearch) {
      payload['tools'] = [
        {'googleSearch': {}},
      ];
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      String errorMsg;
      try {
        final errorBody = jsonDecode(response.body);
        errorMsg =
            errorBody['error']?['message'] ?? 'HTTP ${response.statusCode}';
      } catch (_) {
        errorMsg = 'HTTP error: ${response.statusCode}';
      }
      throw GeminiApiException(errorMsg, statusCode: response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for blocked requests
    final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
    if (promptFeedback != null && promptFeedback['blockReason'] != null) {
      throw Exception(
        'Request was blocked due to ${promptFeedback['blockReason']}.',
      );
    }

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception(
        'Received an invalid response from the AI (no candidates).',
      );
    }

    final parts = candidates[0]['content']['parts'] as List<dynamic>;
    final text = parts.map((p) => p['text'] as String).join('');
    return text.trim();
  }

  /// Retry wrapper with exponential backoff for rate-limit errors.
  Future<String> _callWithRetry(Future<String> Function() apiCall) async {
    int attempt = 0;
    int delay = 1000;

    while (attempt < _maxRetries) {
      try {
        return await apiCall();
      } catch (e) {
        attempt++;
        final errorMessage = e.toString();
        final isRateLimit =
            errorMessage.contains('RESOURCE_EXHAUSTED') ||
            errorMessage.contains('quota') ||
            errorMessage.contains('429');

        if (isRateLimit && attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2;
        } else if (isRateLimit) {
          throw Exception(
            'The service is busy due to high traffic. Please wait a moment and try again.',
          );
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Max retries reached for Gemini API call.');
  }

  /// Clean JSON response from markdown code fences.
  String _cleanJsonResponse(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  // ──────────────────────────────────────────────────────────────
  // PUBLIC API - mirrors the 6 exported functions from geminiService.ts
  // ──────────────────────────────────────────────────────────────

  /// Search for songs by their opening lyrics.
  Future<List<SongInfo>> getSongInfoFromLyrics(String lyricSnippet) async {
    if (lyricSnippet.trim().isEmpty) {
      throw Exception('Lyric snippet cannot be empty.');
    }

    final prompt =
        '''
You are a highly accurate music identification engine. Your most important task is to identify songs that BEGIN WITH the provided lyric snippet. The user has provided at least the first two words.

Lyric Snippet: "$lyricSnippet"

**CRITICAL INSTRUCTIONS:**

1.  **THE "STARTS WITH" RULE IS ABSOLUTE:**
    *   Your search is strictly limited to finding songs where the lyrics **begin with** the provided snippet.
    *   You MUST NOT return songs where the snippet appears in the middle or end of the lyrics.
    *   The user's input may be misspelled or a phonetic approximation. Account for this, but **only for songs that start with that phonetic sound.**

2.  **ABSOLUTE ACCURACY - NO GUESSING:**
    *   For every potential match, you **MUST** use web search to rigorously verify every single piece of metadata.
    *   If you cannot verify a piece of information, omit that key entirely.

3.  **METADATA REQUIREMENTS:** For each song, find if available:
    *   'title', 'artist', 'film', 'composer', 'lyricist', 'language', 'year', 'raga', 'scale'

4.  **COMPREHENSIVE SEARCH:** Return all relevant matches you find and can verify.

5.  **OUTPUT FORMAT:** Valid JSON array of song objects. The entire response text should be ONLY this JSON array. If no songs found, return [].
''';

    final responseText = await _callWithRetry(
      () => _generateContent(prompt, useGoogleSearch: true),
    );

    final jsonText = _cleanJsonResponse(responseText);
    try {
      final list = jsonDecode(jsonText) as List<dynamic>;
      return list
          .map((e) => SongInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception(
        'Received an invalid response from the AI. Please try again.',
      );
    }
  }

  /// Search for films by name.
  Future<List<FilmInfo>> getFilmsByName(String filmQuery) async {
    if (filmQuery.trim().isEmpty) {
      throw Exception('Film name cannot be empty.');
    }

    final prompt =
        '''
You are a highly accurate film database. Your task is to find films that start with a given search query.

Search Query: "$filmQuery"

**CRITICAL INSTRUCTIONS:**
1.  **"STARTS WITH" RULE IS ABSOLUTE:** Find films where the title **BEGINS WITH** the search query.
2.  **COMPREHENSIVE SEARCH:** Use web search to find all relevant films across languages and decades.
3.  **ABSOLUTE ACCURACY:** Verify title, year, and language from multiple sources.
4.  **METADATA:** 'film', 'year', 'language'
5.  **OUTPUT FORMAT:** Valid JSON array. If no films found, return [].
''';

    final responseText = await _callWithRetry(
      () => _generateContent(prompt, useGoogleSearch: true),
    );

    final jsonText = _cleanJsonResponse(responseText);
    try {
      final list = jsonDecode(jsonText) as List<dynamic>;
      return list
          .map((e) => FilmInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception(
        'Received an invalid response from the AI. Please try again.',
      );
    }
  }

  /// Get all songs from a specific film's soundtrack.
  Future<List<SongInfo>> getSongsFromFilm(String filmName) async {
    if (filmName.trim().isEmpty) {
      throw Exception('Film name cannot be empty.');
    }

    final prompt =
        '''
You are a highly accurate music archivist. Your task is to find all the songs from a specific film.

Film Name: "$filmName"

**CRITICAL INSTRUCTIONS:**
1.  **IDENTIFY THE FILM:** Use web search to correctly identify the film.
2.  **FIND ALL SONGS:** Locate the complete, official soundtrack listing.
3.  **ABSOLUTE ACCURACY:** Verify every piece of metadata from multiple sources.
4.  **METADATA:** 'title', 'artist', 'film', 'composer', 'lyricist', 'language', 'year'
5.  **OUTPUT FORMAT:** Valid JSON array. If no songs found, return [].
''';

    final responseText = await _callWithRetry(
      () => _generateContent(prompt, useGoogleSearch: true),
    );

    final jsonText = _cleanJsonResponse(responseText);
    try {
      final list = jsonDecode(jsonText) as List<dynamic>;
      return list
          .map((e) => SongInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception(
        'Received an invalid response from the AI. Please try again.',
      );
    }
  }

  /// Fetch the original lyrics for a song in its native script.
  Future<String> getOriginalLyrics(SongInfo song) async {
    final prompt =
        '''
You are a music archivist. Your task is to provide the full, accurate original lyrics for the following song.

**Song Details:**
*   Title: ${song.title}
*   Artist(s): ${song.artist}
*   Film/Album: ${song.film ?? 'N/A'}
*   Language: ${song.language ?? 'N/A'}
*   Year: ${song.year ?? 'N/A'}

**CRITICAL INSTRUCTIONS:**
1.  **VERIFY THE SONG:** Use web search to find the exact song by Title and Artist.
2.  **ACCURATE LYRICS:** Provide the complete lyrics in the original language script.
3.  **FORMATTING:**
    *   No title or headings. Just lyrics.
    *   Use line breaks to separate verses and stanzas naturally.
    *   For duets, label the start of a singer's part ONLY the first line of a continuous block:
        (M): La la la
        La la la la
        (F): Dee dee dee
4.  **NO TRANSLATIONS/TRANSLITERATIONS.** Original script only.
    If lyrics cannot be found, respond with: "LYRICS_NOT_FOUND"
''';

    final responseText = await _callWithRetry(
      () => _generateContent(prompt, useGoogleSearch: true),
    );

    final lyrics = responseText.trim();
    if (lyrics == 'LYRICS_NOT_FOUND') {
      throw Exception(
        'Could not find the lyrics for this song. It may be an instrumental or the lyrics are not available.',
      );
    }
    return lyrics;
  }

  /// Transliterate lyrics to English phonetics.
  Future<String> generateTransliteration(
    String lyrics,
    String language, {
    bool detailed = false,
  }) async {
    final prompt = detailed
        ? _buildDetailedTransliterationPrompt(lyrics, language)
        : _buildSimpleTransliterationPrompt(lyrics, language);

    final responseText = await _callWithRetry(() => _generateContent(prompt));
    return responseText.trim();
  }

  /// Translate lyrics to English.
  Future<String> generateTranslation(
    String originalLyrics,
    String transliteratedLyrics,
    String language,
  ) async {
    final prompt =
        '''
You are an expert linguist and translator. You will be provided with song lyrics in their original $language script, along with a phonetic English transliteration. Your task is to provide a clear and natural-sounding English translation of the meaning.

**Original Lyrics ($language):**
---
$originalLyrics
---

**Transliterated Lyrics (English Phonetics):**
---
$transliteratedLyrics
---

**CRITICAL INSTRUCTIONS:**
1.  **TRANSLATE (Meaning):** Provide a simple, clear English translation of each line's meaning.
2.  **OUTPUT FORMATTING:**
    *   Process line by line.
    *   Maintain original stanza structure and line breaks.
    *   Just the translation, no other text.
''';

    final responseText = await _callWithRetry(() => _generateContent(prompt));
    return responseText.trim();
  }

  // ── Private prompt builders ────────────────────────────────────

  String _buildDetailedTransliterationPrompt(String lyrics, String language) {
    return '''
You are an expert linguist specializing in phonetics, particularly for languages from the Indian subcontinent. Your task is to process a block of song lyrics written in $language.

**Provided Lyrics:**
---
$lyrics
---

**CRITICAL INSTRUCTIONS:**

Your goal is to create a "Detailed Diction" version of these lyrics using specific capitalization rules:

1.  **TRANSLITERATE (Detailed Phonetics):**
    *   Use **UPPERCASE** for retroflex consonants and **lowercase** for dental:
        *   Retroflex T (ட, ट, ಟ): 'paTTam' | Dental t (த, त, ತ): 'paatham'
        *   Retroflex D (ட, ड, ಡ): 'DanDora' | Dental d (த, द, ದ): 'dhanam'
        *   Retroflex N (ண, ण, ಣ): 'maNi' | Dental n (ந, न, ನ): 'nadi'
    *   **Lateral Approximants:** UPPERCASE L for retroflex (ள, ळ, ಳ), lowercase l for regular.
    *   **Aspirated Consonants:** 'kh', 'gh', 'ch', 'jh', 'th', 'dh', 'ph', 'bh'.
    *   **Vowels:** a, aa, i, ee, u, oo, e, ai, o, au.

2.  **PRESERVE SINGER LABELS** (e.g., (M):, (F):).

3.  **OUTPUT FORMATTING:** Line by line. Maintain stanza structure. No other text.
''';
  }

  String _buildSimpleTransliterationPrompt(String lyrics, String language) {
    return '''
You are an expert linguist specializing in phonetics. Your task is to process a block of song lyrics written in $language.

**Provided Lyrics:**
---
$lyrics
---

**CRITICAL INSTRUCTIONS:**

1.  **TRANSLITERATE (Sound, Not Spelling):**
    *   Convert to English letters based on how it SOUNDS. Intuitive for an English speaker.
    *   Example (Tamil): "நண்பன்" -> "Nanban" (how it sounds), not "Nanpan".

2.  **PRESERVE SINGER LABELS** (e.g., (M):, (F):, Chorus:).

3.  **OUTPUT FORMATTING:** Line by line. Maintain stanza structure and blank lines. No other text.
''';
  }
}

/// Custom exception for Gemini API errors.
class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;

  GeminiApiException(this.message, {this.statusCode});

  @override
  String toString() => 'GeminiApiException: $message (status: $statusCode)';
}
