/// Represents basic song metadata returned from search results.
class SongInfo {
  final String title;
  final String artist;
  final String? film;
  final String? composer;
  final String? lyricist;
  final String? scale;
  final String? raga;
  final String? language;
  final String? year;
  final String? decade;

  SongInfo({
    required this.title,
    required this.artist,
    this.film,
    this.composer,
    this.lyricist,
    this.scale,
    this.raga,
    this.language,
    this.year,
    this.decade,
  });

  factory SongInfo.fromJson(Map<String, dynamic> json) {
    return SongInfo(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      film: json['film'] as String?,
      composer: json['composer'] as String?,
      lyricist: json['lyricist'] as String?,
      scale: json['scale'] as String?,
      raga: json['raga'] as String?,
      language: json['language'] as String?,
      year: json['year'] as String?,
      decade: json['decade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      if (film != null) 'film': film,
      if (composer != null) 'composer': composer,
      if (lyricist != null) 'lyricist': lyricist,
      if (scale != null) 'scale': scale,
      if (raga != null) 'raga': raga,
      if (language != null) 'language': language,
      if (year != null) 'year': year,
      if (decade != null) 'decade': decade,
    };
  }

  SongInfo copyWith({
    String? title,
    String? artist,
    String? film,
    String? composer,
    String? lyricist,
    String? scale,
    String? raga,
    String? language,
    String? year,
    String? decade,
  }) {
    return SongInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      film: film ?? this.film,
      composer: composer ?? this.composer,
      lyricist: lyricist ?? this.lyricist,
      scale: scale ?? this.scale,
      raga: raga ?? this.raga,
      language: language ?? this.language,
      year: year ?? this.year,
      decade: decade ?? this.decade,
    );
  }
}

/// Represents a film match from search.
class FilmInfo {
  final String film;
  final String year;
  final String language;

  FilmInfo({required this.film, required this.year, required this.language});

  factory FilmInfo.fromJson(Map<String, dynamic> json) {
    return FilmInfo(
      film: json['film'] as String? ?? '',
      year: json['year']?.toString() ?? '',
      language: json['language'] as String? ?? '',
    );
  }
}

/// A single line pairing transliteration with its translation.
class TranslationLine {
  final String transliterated;
  final String translated;

  TranslationLine({required this.transliterated, required this.translated});

  factory TranslationLine.fromJson(Map<String, dynamic> json) {
    return TranslationLine(
      transliterated: json['transliterated'] as String? ?? '',
      translated: json['translated'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'transliterated': transliterated, 'translated': translated};
  }
}

/// Extended song data that includes lyrics, transliterations, and translations.
/// This is what gets stored in the local database.
class SongData extends SongInfo {
  final int? id;
  final String? originalLyrics;
  final Map<String, String>? transliterations;
  final Map<String, List<TranslationLine>>? translations;

  SongData({
    this.id,
    required super.title,
    required super.artist,
    super.film,
    super.composer,
    super.lyricist,
    super.scale,
    super.raga,
    super.language,
    super.year,
    super.decade,
    this.originalLyrics,
    this.transliterations,
    this.translations,
  });

  factory SongData.fromSongInfo(
    SongInfo info, {
    int? id,
    String? originalLyrics,
  }) {
    return SongData(
      id: id,
      title: info.title,
      artist: info.artist,
      film: info.film,
      composer: info.composer,
      lyricist: info.lyricist,
      scale: info.scale,
      raga: info.raga,
      language: info.language,
      year: info.year,
      decade: info.decade,
      originalLyrics: originalLyrics,
    );
  }

  /// Convert from database row.
  factory SongData.fromDbMap(Map<String, dynamic> map) {
    return SongData(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      film: map['film'] as String?,
      composer: map['composer'] as String?,
      lyricist: map['lyricist'] as String?,
      scale: map['scale'] as String?,
      raga: map['raga'] as String?,
      language: map['language'] as String?,
      year: map['year'] as String?,
      decade: map['decade'] as String?,
      originalLyrics: map['originalLyrics'] as String?,
    );
  }

  /// Convert to database row.
  Map<String, dynamic> toDbMap() {
    final map = <String, dynamic>{
      'title': title,
      'artist': artist,
      'film': film,
      'composer': composer,
      'lyricist': lyricist,
      'scale': scale,
      'raga': raga,
      'language': language,
      'year': year,
      'decade': decade,
      'originalLyrics': originalLyrics,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  SongData copyWithData({
    int? id,
    String? originalLyrics,
    Map<String, String>? transliterations,
    Map<String, List<TranslationLine>>? translations,
  }) {
    return SongData(
      id: id ?? this.id,
      title: title,
      artist: artist,
      film: film,
      composer: composer,
      lyricist: lyricist,
      scale: scale,
      raga: raga,
      language: language,
      year: year,
      decade: decade,
      originalLyrics: originalLyrics ?? this.originalLyrics,
      transliterations: transliterations ?? this.transliterations,
      translations: translations ?? this.translations,
    );
  }
}
