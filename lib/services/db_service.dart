import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/song_models.dart';

/// Local SQLite database service — replaces the web app's IndexedDB layer.
class DbService {
  static const String _dbName = 'lyriclearn.db';
  static const int _dbVersion = 1;
  static const String _tableSongs = 'songs';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableSongs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            film TEXT,
            composer TEXT,
            lyricist TEXT,
            scale TEXT,
            raga TEXT,
            language TEXT,
            year TEXT,
            decade TEXT,
            originalLyrics TEXT,
            UNIQUE(title, artist)
          )
        ''');
        // Create index for language lookups
        await db.execute('CREATE INDEX idx_language ON $_tableSongs(language)');
      },
    );
  }

  /// Look up a song by its title + artist combo.
  Future<SongData?> getSongByTitleAndArtist(String title, String artist) async {
    final db = await database;
    final results = await db.query(
      _tableSongs,
      where: 'title = ? AND artist = ?',
      whereArgs: [title, artist],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SongData.fromDbMap(results.first);
  }

  /// Insert or update a song (upsert).
  Future<SongData> saveSong(SongData song) async {
    final db = await database;
    final map = song.toDbMap();

    if (song.id != null) {
      await db.update(_tableSongs, map, where: 'id = ?', whereArgs: [song.id]);
      return song;
    }

    // Try to find existing by title+artist first
    final existing = await getSongByTitleAndArtist(song.title, song.artist);
    if (existing != null) {
      map['id'] = existing.id;
      await db.update(
        _tableSongs,
        map,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return song.copyWithData(id: existing.id);
    }

    final id = await db.insert(_tableSongs, map);
    return song.copyWithData(id: id);
  }

  /// Get total number of songs in the database.
  Future<int> countSongs() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableSongs',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get all songs.
  Future<List<SongData>> getAllSongs() async {
    final db = await database;
    final results = await db.query(_tableSongs);
    return results.map((m) => SongData.fromDbMap(m)).toList();
  }

  /// Get all distinct languages (excluding English).
  Future<List<String>> getAvailableLanguages() async {
    final db = await database;
    final results = await db.rawQuery(
      "SELECT DISTINCT language FROM $_tableSongs WHERE language IS NOT NULL AND LOWER(language) != 'english' ORDER BY language",
    );
    return results.map((r) => r['language'] as String).toList();
  }

  /// Get songs filtered by language.
  Future<List<SongData>> getSongsByLanguage(String language) async {
    final db = await database;
    final results = await db.query(
      _tableSongs,
      where: 'language = ?',
      whereArgs: [language],
    );
    return results.map((m) => SongData.fromDbMap(m)).toList();
  }

  /// Delete all songs.
  Future<void> deleteAllSongs() async {
    final db = await database;
    await db.delete(_tableSongs);
  }

  /// Bulk save/update songs.
  Future<void> bulkSaveSongs(List<SongData> songs) async {
    for (final song in songs) {
      try {
        await saveSong(song);
      } catch (e) {
        // Continue with other songs even if one fails
      }
    }
  }

  /// Pre-seed the database with example songs.
  Future<void> preseedDatabase() async {
    await bulkSaveSongs(_exampleSongs);
  }
}

// ─── Pre-seed data (mirrors the web app's exampleSongs) ──────────────────

final List<SongData> _exampleSongs = [
  SongData(
    title: 'Nilaave Vaa',
    artist: 'S. P. Balasubrahmanyam',
    film: 'Mouna Ragam',
    composer: 'Ilaiyaraaja',
    lyricist: 'Vaali',
    language: 'Tamil',
    year: '1986',
    decade: '1980s',
    scale: 'A minor',
  ),
  SongData(
    title: 'Krishna Nee Begane Baro',
    artist: 'Various Artists',
    language: 'Kannada',
    raga: 'Yamuna Kalyani',
    composer: 'Vyasatirtha',
    lyricist: 'Vyasatirtha',
    year: '16th Century',
    decade: 'Pre-1900s',
  ),
  SongData(
    title: 'Chaleya',
    artist: 'Arijit Singh, Shilpa Rao',
    film: 'Jawan',
    composer: 'Anirudh Ravichander',
    lyricist: 'Kumaar',
    language: 'Hindi',
    year: '2023',
    decade: '2020s',
    scale: 'D Major',
  ),
  SongData(
    title: 'Samajavaragamana',
    artist: 'Sid Sriram',
    film: 'Ala Vaikunthapurramuloo',
    composer: 'Thaman S',
    lyricist: 'Seetharama Sastry',
    language: 'Telugu',
    year: '2019',
    decade: '2010s',
    scale: 'G minor',
  ),
  SongData(
    title: 'Titi Me Preguntó',
    artist: 'Bad Bunny',
    film: 'Un Verano Sin Ti',
    composer: 'Benito Martínez, MAG, La Paciencia',
    lyricist: 'Benito Martínez',
    language: 'Latin',
    year: '2022',
    decade: '2020s',
    scale: 'F# minor',
  ),
  SongData(
    title: 'Munbe Vaa',
    artist: 'Shreya Ghoshal, Naresh Iyer',
    film: 'Sillunu Oru Kaadhal',
    composer: 'A. R. Rahman',
    lyricist: 'Vaali',
    language: 'Tamil',
    year: '2006',
    decade: '2000s',
    raga: 'Bageshri',
  ),
  SongData(
    title: 'Malare',
    artist: 'Vijay Yesudas',
    film: 'Premam',
    composer: 'Rajesh Murugesan',
    lyricist: 'Shabareesh Varma',
    language: 'Malayalam',
    year: '2015',
    decade: '2010s',
    scale: 'C# minor',
  ),
  SongData(
    title: 'Spring Day',
    artist: 'BTS',
    film: 'You Never Walk Alone',
    composer: 'RM, Suga, Adora, "hitman" bang, Arlissa Ruppert, Peter Ibsen',
    lyricist: 'RM, Suga, Adora, "hitman" bang, Arlissa Ruppert, Peter Ibsen',
    language: 'K-Pop',
    year: '2017',
    decade: '2010s',
    scale: 'E-flat Major',
  ),
  SongData(
    title: 'Lemon',
    artist: 'Kenshi Yonezu',
    film: 'Lemon',
    composer: 'Kenshi Yonezu',
    lyricist: 'Kenshi Yonezu',
    language: 'J-Pop',
    year: '2018',
    decade: '2010s',
    scale: 'B Major',
  ),
  SongData(
    title: 'Nilave Mugam Kaattu',
    artist: 'S.P. Balasubrahmanyam, S. Janaki',
    film: 'Ejamaan',
    composer: 'Ilaiyaraaja',
    lyricist: 'Vaali',
    language: 'Tamil',
    year: '1993',
    decade: '1990s',
    raga: 'Sindhubhairavi',
  ),
  SongData(
    title: 'Oru Naalum',
    artist: 'S.P. Balasubrahmanyam, S. Janaki',
    film: 'Ejamaan',
    composer: 'Ilaiyaraaja',
    lyricist: 'Vaali',
    language: 'Tamil',
    year: '1993',
    decade: '1990s',
    raga: 'Sindhubhairavi',
  ),
  SongData(
    title: 'Yeh Aatha',
    artist: 'S. P. Balasubrahmanyam',
    film: 'Payanangal Mudivathillai',
    composer: 'Ilaiyaraaja',
    lyricist: 'Gangai Amaran',
    language: 'Tamil',
    year: '1982',
    decade: '1980s',
  ),
];
