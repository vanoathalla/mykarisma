import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ─── Getter lazy-initialize ───────────────────────────────────────────────

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('karisma.db');
    return _database!;
  }

  // ─── Inisialisasi ─────────────────────────────────────────────────────────

  Future<Database> _initDB(String filePath) async {
    // Di web, getDatabasesPath() tidak tersedia — gunakan nama file langsung
    final String path;
    if (kIsWeb) {
      path = filePath; // sqflite_common_ffi_web pakai nama file saja
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE member (
        id_member      INTEGER PRIMARY KEY AUTOINCREMENT,
        nama           TEXT NOT NULL,
        nama_panggilan TEXT,
        no_hp          TEXT,
        role           TEXT NOT NULL,
        rt             TEXT,
        password_hash  TEXT,
        foto_path      TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE acara (
        id_acara  INTEGER PRIMARY KEY AUTOINCREMENT,
        nama      TEXT NOT NULL,
        tanggal   TEXT NOT NULL,
        kategori  TEXT NOT NULL,
        tipe      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE catatan (
        id_catatan INTEGER PRIMARY KEY AUTOINCREMENT,
        judul      TEXT NOT NULL,
        acara      TEXT,
        isi        TEXT,
        tanggal    TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE keuangan (
        id_keuangan INTEGER PRIMARY KEY AUTOINCREMENT,
        tipe        TEXT NOT NULL,
        nama        TEXT NOT NULL,
        tanggal     TEXT NOT NULL,
        jumlah      INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dokumentasi (
        id_dokumentasi INTEGER PRIMARY KEY AUTOINCREMENT,
        nama           TEXT NOT NULL,
        url            TEXT NOT NULL,
        tanggal        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE landmark (
        id_landmark INTEGER PRIMARY KEY AUTOINCREMENT,
        nama        TEXT NOT NULL,
        latitude    REAL NOT NULL,
        longitude   REAL NOT NULL,
        deskripsi   TEXT,
        id_acara    INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sesi_game (
        id_sesi INTEGER PRIMARY KEY AUTOINCREMENT,
        skor    INTEGER NOT NULL,
        level   INTEGER NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE feedback (
        id_feedback INTEGER PRIMARY KEY AUTOINCREMENT,
        nama        TEXT,
        rating      INTEGER NOT NULL,
        kategori    TEXT NOT NULL,
        isi         TEXT NOT NULL,
        tanggal     TEXT NOT NULL
      )
    ''');
  }

  // ─── Upgrade ──────────────────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE member ADD COLUMN password_hash TEXT');
      await db.execute('ALTER TABLE member ADD COLUMN foto_path TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS landmark (
          id_landmark INTEGER PRIMARY KEY AUTOINCREMENT,
          nama        TEXT NOT NULL,
          latitude    REAL NOT NULL,
          longitude   REAL NOT NULL,
          deskripsi   TEXT,
          id_acara    INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sesi_game (
          id_sesi INTEGER PRIMARY KEY AUTOINCREMENT,
          skor    INTEGER NOT NULL,
          level   INTEGER NOT NULL,
          tanggal TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS feedback (
          id_feedback INTEGER PRIMARY KEY AUTOINCREMENT,
          nama        TEXT,
          rating      INTEGER NOT NULL,
          kategori    TEXT NOT NULL,
          isi         TEXT NOT NULL,
          tanggal     TEXT NOT NULL
        )
      ''');
    }
  }

  // ─── Operasi Member ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllMembers() async {
    final db = await database;
    return db.query('member');
  }

  Future<int> insertMember(MemberModel member) async {
    final db = await database;

    // Jangan sertakan id_member saat insert baru agar AUTOINCREMENT bekerja.
    final isNewRecord = member.id.isEmpty || member.id == '0';
    final Map<String, dynamic> data;

    if (isNewRecord) {
      data = {
        'nama': member.nama,
        'nama_panggilan': member.panggilan,
        'no_hp': member.noHp,
        'role': member.role,
        'rt': member.rt,
      };
    } else {
      data = member.toMap();
    }

    return db.insert(
      'member',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MemberModel?> getMemberByCredentials(
    String namaPanggilan,
    String noHp,
  ) async {
    final db = await database;
    final rows = await db.query(
      'member',
      where: 'nama_panggilan = ? AND no_hp = ?',
      whereArgs: [namaPanggilan, noHp],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return MemberModel.fromJson(rows.first);
  }

  Future<MemberModel?> getMemberByUsername(String namaPanggilan) async {
    final db = await database;
    final rows = await db.query(
      'member',
      where: 'nama_panggilan = ?',
      whereArgs: [namaPanggilan],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MemberModel.fromJson(rows.first);
  }

  // ─── Operasi Acara ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllAcara() async {
    final db = await database;
    return db.query('acara');
  }

  Future<int> insertAcara(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('acara', data);
  }

  Future<int> updateAcara(String id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'acara',
      data,
      where: 'id_acara = ?',
      whereArgs: [int.tryParse(id) ?? 0],
    );
  }

  // ─── Operasi Catatan ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllCatatan() async {
    final db = await database;
    return db.query('catatan', orderBy: 'tanggal DESC');
  }

  Future<int> insertCatatan(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('catatan', data);
  }

  Future<int> updateCatatan(String id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'catatan',
      data,
      where: 'id_catatan = ?',
      whereArgs: [int.tryParse(id) ?? 0],
    );
  }

  Future<int> deleteCatatan(String id) async {
    final db = await database;
    return db.delete(
      'catatan',
      where: 'id_catatan = ?',
      whereArgs: [int.tryParse(id) ?? 0],
    );
  }

  // ─── Operasi Keuangan ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllKeuangan() async {
    final db = await database;
    return db.query('keuangan', orderBy: 'tanggal DESC');
  }

  Future<int> insertKeuangan(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('keuangan', data);
  }

  Future<int> deleteKeuangan(String id) async {
    final db = await database;
    return db.delete(
      'keuangan',
      where: 'id_keuangan = ?',
      whereArgs: [int.tryParse(id) ?? 0],
    );
  }

  // ─── Operasi Dokumentasi ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllDokumentasi() async {
    final db = await database;
    return db.query('dokumentasi');
  }

  // ─── Operasi Landmark ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllLandmarks() async {
    final db = await database;
    return db.query('landmark');
  }

  Future<int> insertLandmark(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('landmark', data);
  }

  // ─── Operasi Sesi Game ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllGameSessions() async {
    final db = await database;
    return db.query('sesi_game', orderBy: 'skor DESC');
  }

  Future<int> insertGameSession(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('sesi_game', data);
  }

  // ─── Operasi Feedback ─────────────────────────────────────────────────────

  Future<int> insertFeedback(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('feedback', data);
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  /// Seed data awal: insert satu admin jika tabel member masih kosong.
  /// password_hash adalah SHA-256 dari 'admin123'.
  Future<void> seedData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM member'),
    );

    if (count == null || count == 0) {
      await db.insert(
        'member',
        {
          'nama': 'Admin RT',
          'nama_panggilan': 'admin',
          'no_hp': 'admin123',
          'role': 'admin',
          'rt': '01',
          // SHA-256 dari 'admin123'
          'password_hash':
              '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Hapus semua data dari seluruh tabel tanpa DROP tabel.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('member');
    await db.delete('acara');
    await db.delete('catatan');
    await db.delete('keuangan');
    await db.delete('dokumentasi');
    await db.delete('landmark');
    await db.delete('sesi_game');
    await db.delete('feedback');
  }
}
