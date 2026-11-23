import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  static final SupabaseClient _supabase =
      Supabase.instance.client;

  /// Качване на всички локални данни към Supabase
  static Future<void> syncToCloud() async {
    try {
      final db = await DBHelper.instance.database;

      // =====================
      // SHIFTS
      // =====================

      final shifts = await db.query('shifts');

      final formattedShifts = shifts.map((s) {
        return {
          'id': s['id'],
          'date': s['date'],
          'routenumber': s['routeNumber'],
          'locomotivenumber': s['locomotiveNumber'],
          'trainnumber': s['trainNumber'],
          'destination': s['destination'],
          'starttime': s['startTime'],
          'endtime': s['endTime'],
          'nighthours': s['nightHours'],
          'kilometers': s['kilometers'],
          'noservice': s['noService'],
          'nationalhours': s['nationalHours'],
          'month': s['month'],
          'year': s['year'],
        };
      }).toList();

      if (formattedShifts.isNotEmpty) {
        await _supabase.from('shifts').upsert(
              formattedShifts,
              onConflict: 'id',
            );
      }

      // =====================
      // SPECIAL DAYS
      // =====================

      final specialDays = await db.query('special_days');

      if (specialDays.isNotEmpty) {
        await _supabase.from('special_days').upsert(
              specialDays,
              onConflict: 'date',
            );
      }

      debugPrint(
        '✅ Sync completed. '
        'Shifts: ${formattedShifts.length}, '
        'SpecialDays: ${specialDays.length}',
      );
    } catch (e, s) {
      debugPrint('❌ Sync error: $e');
      debugPrint(s.toString());
    }
  }

  static Future<void> deleteShiftFromCloud(int id) async {
  try {
    await _supabase
        .from('shifts')
        .delete()
        .eq('id', id);

    debugPrint('✅ Cloud shift deleted: $id');
  } catch (e) {
    debugPrint('❌ Cloud delete error: $e');
  }
}

static Future<void> deleteSpecialDayFromCloud(String date) async {
  try {
    await _supabase
        .from('special_days')
        .delete()
        .eq('date', date);

    debugPrint('✅ Cloud special day deleted: $date');
  } catch (e) {
    debugPrint('❌ Cloud delete error: $e');
  }
}

static Future<void> restoreFromCloud() async {
  try {
    final db = await DBHelper.instance.database;

    // =====================
    // SHIFTS
    // =====================

    final shifts =
        await _supabase.from('shifts').select();

    for (final shift in shifts) {
      await db.insert(
        'shifts',
        {
          'id': shift['id'],
          'date': shift['date'],
          'routeNumber': shift['routenumber'],
          'locomotiveNumber': shift['locomotivenumber'],
          'trainNumber': shift['trainnumber'],
          'destination': shift['destination'],
          'startTime': shift['starttime'],
          'endTime': shift['endtime'],
          'nightHours': shift['nighthours'],
          'kilometers': shift['kilometers'],
          'noService': shift['noservice'],
          'nationalHours': shift['nationalhours'],
          'month': shift['month'],
          'year': shift['year'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // =====================
    // SPECIAL DAYS
    // =====================

    final specialDays =
        await _supabase.from('special_days').select();

    for (final day in specialDays) {
      await db.insert(
        'special_days',
        {
          'date': day['date'],
          'type': day['type'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    debugPrint(
      '✅ RESTORE DONE '
      'Shifts=${shifts.length} '
      'SpecialDays=${specialDays.length}',
    );
  } catch (e, s) {
    debugPrint('❌ RESTORE ERROR: $e');
    debugPrint(s.toString());
  }
}

static Future<void> autoRestoreIfNeeded() async {
  try {
    final isEmpty =
        await DBHelper.instance.isDatabaseEmpty();

    if (!isEmpty) {
      debugPrint(
        '✅ Local database contains data. Restore skipped.',
      );
      return;
    }

    debugPrint(
      '☁ Empty database detected. Starting restore...',
    );

    await restoreFromCloud();

  } catch (e) {
    debugPrint(
      '❌ Auto restore failed: $e',
    );
  }
}
}