import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class StationsDB {
  static final StationsDB instance = StationsDB._init();
  StationsDB._init();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stations.db');

    // копиране при първо стартиране
    final exists = await databaseExists(path);

    if (!exists) {
      ByteData data = await rootBundle.load('assets/database/stations.db');
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> searchStation(String query) async {
    final db = await database;

    return await db.query(
      'stations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<void> updatePhone(int id, String phone) async {
    final db = await database;

    await db.update(
      'stations',
      {'phone': phone},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}