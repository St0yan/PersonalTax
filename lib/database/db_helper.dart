import 'package:personal_tax/pages/home_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shift.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shifts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        routeNumber INTEGER,
        locomotiveNumber INTEGER,
        trainNumber INTEGER,
        destination TEXT,
        startTime TEXT,
        endTime TEXT,
        nightHours TEXT,
        kilometers INTEGER,
        noService INTEGER,
        nationalHours TEXT,
        month INTEGER,
        year INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        name TEXT,
        year INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE special_days (
        date TEXT PRIMARY KEY,
        type TEXT NOT NULL
      )
    ''');
  }

  // ---------- INSERT ----------
  Future<int> insertShift(Shift shift) async {
    final db = await instance.database;
    return await db.insert('shifts', shift.toMap());
  }

  // ---------- UPDATE ----------
  Future<int> updateShift(Shift shift) async {
    final db = await instance.database;
    return await db.update(
      'shifts',
      shift.toMap(),
      where: 'id = ?',
      whereArgs: [shift.id],
    );
  }

  // ---------- DELETE ----------
  Future<int> deleteShift(int id) async {
    final db = await instance.database;
    return await db.delete(
      'shifts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- GET BY DATE ----------
  Future<List<Shift>> getShiftsByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'shifts',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((e) => Shift.fromMap(e)).toList();
  }

  // ---------- GET BY MONTH ----------
  Future<List<Shift>> getShiftsByMonth(int month, int year) async {
    final db = await instance.database;

    final monthStr = month.toString().padLeft(2, '0');
    final yearStr = year.toString();

    final result = await db.query(
      'shifts',
      where: "date LIKE ?",
      whereArgs: ["%.$monthStr.$yearStr"],
      orderBy: 'date ASC',
    );

    return result.map((e) => Shift.fromMap(e)).toList();
  }

  // ---------- GET ALL ----------
  Future<List<Shift>> getAllShifts() async {
    final db = await instance.database;
    final result = await db.query('shifts');
    return result.map((e) => Shift.fromMap(e)).toList();
  }

  Future<void> insertHoliday(String date, String name, int year) async {
    final db = await instance.database;
    await db.insert('holidays', {
      'date': date,
      'name': name,
      'year': year,
    });
  }

  Future<List<Map<String, dynamic>>> getHolidays(int year) async {
    final db = await instance.database;
    return await db.query(
      'holidays',
      where: 'year = ?',
      whereArgs: [year],
    );
  }

  Future<void> clearHolidays(int year) async {
    final db = await instance.database;
    await db.delete(
      'holidays',
      where: 'year = ?',
      whereArgs: [year],
    );
  }
  
  Future<void> addVacationRange(DateTime start, int days) async {
    final db = await database;

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));

      // Пропускаме събота и неделя
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // Пропускаме официални празници и компенсаторни дни
      final key = "${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}";
      if (HomePage.globalHolidayKeys.contains(key)) {
        continue;
      }

      final formatted =
          "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";

      await db.insert(
        'special_days',
        {'date': formatted, 'type': 'vacation'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addSickRange(DateTime start, int days) async {
    final db = await database;

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));

      // Пропускаме събота и неделя
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // Пропускаме официални празници и компенсаторни дни
      final key = "${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}";
      if (HomePage.globalHolidayKeys.contains(key)) {
        continue;
      }

      final formatted =
          "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";

      await db.insert(
        'special_days',
        {'date': formatted, 'type': 'sick'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSpecialDaysForMonth(int month, int year) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT * FROM special_days
      WHERE substr(date, 4, 2) = ?
      AND substr(date, 7, 4) = ?
      ORDER BY date ASC
    ''', [
      month.toString().padLeft(2, '0'),
      year.toString(),
    ]);
  }

  Future<void> deleteSpecialDay(String date) async {
    final db = await database;
    await db.delete(
      'special_days',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> getAbsencesForMonth(int month, int year) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT * FROM absences
      WHERE strftime('%m', date) = ? AND strftime('%Y', date) = ?
    ''', [
      month.toString().padLeft(2, '0'),
      year.toString(),
    ]);

    return result;
  }
}