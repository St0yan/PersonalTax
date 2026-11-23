import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';

class YearlyStatisticsPage extends StatefulWidget {
  const YearlyStatisticsPage({super.key});

  @override
  _YearlyStatisticsPageState createState() => _YearlyStatisticsPageState();
}

class _YearlyStatisticsPageState extends State<YearlyStatisticsPage> {
  int selectedYear = DateTime.now().year;

  // Totals
  String totalHours = "00:00";
  String totalNightHours = "00:00";
  String totalNationalHours = "00:00";
  int totalKilometers = 0;
  int totalNoService = 0;

  int workingDays = 0;
  int holidayDays = 0;
  int yearlyNorm = 0;

  // Monthly breakdown
  Map<int, List<Shift>> monthlyShifts = {};

  @override
  void initState() {
    super.initState();
    _loadYearlyStatistics();
  }

  // ---------- SUM TIME ----------
  String sumTimes(List<String> times) {
    int totalMinutes = 0;

    for (var t in times) {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      totalMinutes += h * 60 + m;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  // ---------- LOAD YEAR ----------
  Future<void> _loadYearlyStatistics() async {
    monthlyShifts.clear();

    // Load all months
    for (int month = 1; month <= 12; month++) {
      final shifts = await DBHelper.instance.getShiftsByMonth(month, selectedYear);
      monthlyShifts[month] = shifts;
    }

    _calculateTotals();
    await _calculateWorkingDays();

    setState(() {});
  }

  // ---------- CALCULATE TOTALS ----------
  void _calculateTotals() {
    List<String> allHours = [];
    List<String> allNight = [];
    List<String> allNational = [];

    totalKilometers = 0;
    totalNoService = 0;

    for (int m = 1; m <= 12; m++) {
      for (var s in monthlyShifts[m]!) {
        // Work hours
        final start = s.startTime.split(':');
        final end = s.endTime.split(':');

        int startMinutes = int.parse(start[0]) * 60 + int.parse(start[1]);
        int endMinutes = int.parse(end[0]) * 60 + int.parse(end[1]);

        if (endMinutes < startMinutes) {
          endMinutes += 24 * 60;
        }

        final diff = endMinutes - startMinutes;
        final h = diff ~/ 60;
        final m = diff % 60;

        allHours.add("${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}");

        allNight.add(s.nightHours);
        allNational.add(s.nationalHours);

        totalKilometers += s.kilometers;
        totalNoService += s.noService;
      }
    }

    totalHours = sumTimes(allHours);
    totalNightHours = sumTimes(allNight);
    totalNationalHours = sumTimes(allNational);
  }

  // ---------- WORKING DAYS ----------
  Future<void> _calculateWorkingDays() async {
    workingDays = 0;
    holidayDays = 0;

    final holidays = await DBHelper.instance.getHolidays(selectedYear);
    final holidayDates = holidays.map((e) => e['date'] as String).toList();

    for (int month = 1; month <= 12; month++) {
      int daysInMonth = DateUtils.getDaysInMonth(selectedYear, month);

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(selectedYear, month, day);

        final iso = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
        bool isHoliday = holidayDates.contains(iso);

        if (isWeekend || isHoliday) {
          holidayDays++;
        } else {
          workingDays++;
        }
      }
    }

    yearlyNorm = workingDays * 8;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Годишна статистика")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: selectedYear,
              items: List.generate(10, (i) => DateTime.now().year - 5 + i)
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text("$y"),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedYear = v!);
                _loadYearlyStatistics();
              },
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  _stat("Общо часове", totalHours),
                  _stat("Нощен труд", totalNightHours),
                  _stat("Национални", totalNationalHours),
                  _stat("Километри", "$totalKilometers"),
                  _stat("Без служба", "$totalNoService"),
                  Divider(),
                  _stat("Работни дни", "$workingDays"),
                  _stat("Почивни дни", "$holidayDays"),
                  _stat("Годишна норма", "$yearlyNorm часа"),
                  Divider(),
                  SizedBox(height: 10),
                  Text("Разбивка по месеци", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ..._buildMonthlyBreakdown(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildMonthlyBreakdown() {
    List<String> monthNames = [
      "Януари", "Февруари", "Март", "Април", "Май", "Юни",
      "Юли", "Август", "Септември", "Октомври", "Ноември", "Декември"
    ];

    return List.generate(12, (i) {
      final month = i + 1;
      final shifts = monthlyShifts[month]!;

      final hours = sumTimes(shifts.map((s) {
        final start = s.startTime.split(':');
        final end = s.endTime.split(':');

        int startMinutes = int.parse(start[0]) * 60 + int.parse(start[1]);
        int endMinutes = int.parse(end[0]) * 60 + int.parse(end[1]);

        if (endMinutes < startMinutes) endMinutes += 24 * 60;

        final diff = endMinutes - startMinutes;
        final h = diff ~/ 60;
        final m = diff % 60;

        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
      }).toList());

      return ListTile(
        title: Text(monthNames[i]),
        subtitle: Text("Часове: $hours | Смени: ${shifts.length}"),
      );
    });
  }
}