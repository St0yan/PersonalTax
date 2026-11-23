import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';

class HolidayService {
  Future<void> fetchAndCacheHolidays(int year) async {
    final url = Uri.parse("https://date.nager.at/api/v3/PublicHolidays/$year/BG");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      // изчистваме старите празници за годината
      await DBHelper.instance.clearHolidays(year);

      for (var item in data) {
        await DBHelper.instance.insertHoliday(
          item['date'],        // формат YYYY-MM-DD
          item['localName'],   // име на празника
          year,
        );
      }
    }
  }
}