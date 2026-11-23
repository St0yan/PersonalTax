class SyncService {
  static Future<void> autoSync() async {
    try {
      final db = await DBHelper.instance.database;

      // Локални записи
      final shiftCountResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM shifts');

      final specialDaysCountResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM special_days');

      final localShiftCount = shiftCountResult.first['count'] as int;
      final localSpecialCount = specialDaysCountResult.first['count'] as int;

      // Supabase записи
      final remoteShifts = await Supabase.instance.client
          .from('shifts')
          .select('id');

      final remoteSpecialDays = await Supabase.instance.client
          .from('special_days')
          .select('date');

      final remoteShiftCount = remoteShifts.length;
      final remoteSpecialCount = remoteSpecialDays.length;

      final localTotal = localShiftCount + localSpecialCount;
      final remoteTotal = remoteShiftCount + remoteSpecialCount;

      if (localTotal != remoteTotal) {
        await syncToCloud();
      }
    } catch (e) {
      debugPrint('AutoSync error: $e');
    }
  }

  static Future<void> syncToCloud() async {
    final db = await DBHelper.instance.database;

    // Смени
    final shifts = await db.query('shifts');

    for (var shift in shifts) {
      await Supabase.instance.client
          .from('shifts')
          .upsert(shift);
    }

    // Отпуски и болнични
    final specialDays = await db.query('special_days');

    for (var day in specialDays) {
      await Supabase.instance.client
          .from('special_days')
          .upsert(day);
    }

    debugPrint('Sync completed');
  }
}