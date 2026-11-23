import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';
import '../services/excel_export_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<Shift> monthlyShifts = [];

  String totalHours = "00:00";
  String totalNightHours = "00:00";
  String totalNationalHours = "00:00";
  int totalKilometers = 0;
  int totalNoService = 0;

  int workingDays = 0;
  int holidayDays = 0;
  int monthlyNorm = 0;

  int? filterTrain;
  int? filterLoco;
  String? filterDestination;

  List<int> availableTrains = [];
  List<int> availableLocos = [];
  List<String> availableDestinations = [];

  double moneyKilometers = 0.0;
  double moneyNightHours = 0.0;
  double moneyNationalHours = 0.0;
  double moneyNoService = 0.0;
  double hourlyRate = 0.0;

  int workedWeekdays = 0;
  int workedWeekends = 0;
  int freeWeekdays = 0;
  int freeWeekends = 0;

  int totalWorkedDays = 0;
  int totalFreeDays = 0;

  double normPercent = 0;
  double remainingHours = 0;

  int vacationDays = 0;
  int sickDays = 0;

  String selectedSpecialType = "vacation";
  DateTime? selectedSpecialStartDate;

  final specialStartDateController = TextEditingController();
  final specialDaysCountController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  int parseTimeToMinutes(String time) {
    if (!time.contains(":")) return 0;
    final parts = time.split(":");
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  // ---------- LOAD SHIFTS ----------
  Future<void> _loadStatistics() async {
    final shifts = await DBHelper.instance.getShiftsByMonth(selectedMonth, selectedYear);

    setState(() {
      monthlyShifts = shifts;
      filterTrain = null;
      filterLoco = null;
      filterDestination = null;
    });

    availableTrains = monthlyShifts
      .map((s) => s.trainNumber)
      .where((n) => n != null)
      .cast<int>()
      .toSet()
      .toList()
    ..sort();

  availableLocos = monthlyShifts
      .map((s) => s.locomotiveNumber)
      .where((n) => n != null)
      .cast<int>()
      .toSet()
      .toList()
    ..sort();

  availableDestinations = monthlyShifts
      .map((s) => s.destination)
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

    await _calculateWorkingDays();
    _calculateTotals();

    setState(() {});
  }

  // ---------- SUMMING TIME ----------
  String sumTimes(List<String> times) {
    int totalMinutes = 0;

    for (var t in times) {
      if (t.trim().isEmpty || !t.contains(':')) continue;

      final parts = t.split(':');
      if (parts.length != 2) continue;

      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;

      totalMinutes += h * 60 + m;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  // ---------- CALCULATE TOTALS ----------
  void _calculateTotals() {
    int totalMinutes = 0;

    // 1) Часове от реални смени
    for (var s in monthlyShifts) {
      final start = s.startTime.split(':');
      final end = s.endTime.split(':');

      int startMinutes = int.parse(start[0]) * 60 + int.parse(start[1]);
      int endMinutes = int.parse(end[0]) * 60 + int.parse(end[1]);

      if (endMinutes < startMinutes) {
        endMinutes += 24 * 60;
      }

      totalMinutes += (endMinutes - startMinutes);
    }

    // 2) Добавяме отпуск: 8 часа на ден
    totalMinutes += vacationDays * 8 * 60;

    // 3) totalHours
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    totalHours = "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

    // 4) Процент и оставащи часове
    if (monthlyNorm > 0) {
      normPercent = (totalMinutes / (monthlyNorm * 60)) * 100;
      remainingHours = (monthlyNorm * 60 - totalMinutes) / 60;
    } else {
      normPercent = 0;
      remainingHours = 0;
    }

    // 5) Останалите изчисления
    totalNightHours = sumTimes(monthlyShifts.map((s) => s.nightHours).toList());
    totalNationalHours = sumTimes(monthlyShifts.map((s) => s.nationalHours).toList());

    totalKilometers = monthlyShifts.fold(0, (sum, s) => sum + s.kilometers);
    totalNoService = monthlyShifts.fold(0, (sum, s) => sum + s.noService);

    moneyKilometers = totalKilometers * 0.08;

    final nightMinutes = parseTimeToMinutes(totalNightHours);
    moneyNightHours = (nightMinutes / 60) * 2.05;

    final nationalMinutes = parseTimeToMinutes(totalNationalHours);
    moneyNationalHours = (nationalMinutes / 60) * (hourlyRate * 2);

    moneyNoService = totalNoService * 0.06;
  }

  List<String> expandWithCompensatoryDays(List<String> holidays) {
      final Set<String> result = holidays.toSet();

      for (var iso in holidays) {
        final date = DateTime.parse(iso);

        if (date.weekday == DateTime.saturday) {
          final monday = date.add(Duration(days: 2));
          final mIso = "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
          result.add(mIso);
        }

        if (date.weekday == DateTime.sunday) {
          final monday = date.add(Duration(days: 1));
          final mIso = "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
          result.add(mIso);
        }
      }

      return result.toList();
    }

  // ---------- WORKING DAYS & NORM ----------
  Future<void> _calculateWorkingDays() async {

    final db = await DBHelper.instance.database;

    final special = await db.query('special_days');

    final specialDays = {
      for (var s in special) s['date'] as String: s['type'] as String
    };

    int daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);

    // Взимаме празниците от базата (формат YYYY-MM-DD)
    final rawHolidays = await _getHolidayDates(selectedYear);
    final holidayList = expandWithCompensatoryDays(rawHolidays);


    workingDays = 0;
    holidayDays = 0;

    // --- НОВИ ПОЛЕТА ---
    workedWeekdays = 0;
    workedWeekends = 0;
    freeWeekdays = 0;
    freeWeekends = 0;

    vacationDays = 0;
    sickDays = 0;

    // Списък с дати, в които имаш смяна
    final shiftDates = monthlyShifts.map((s) => s.date).toSet();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedYear, selectedMonth, day);

      final iso = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      bool isHoliday = holidayList.contains(iso);

      if (isWeekend || isHoliday) {
        holidayDays++;
      } else {
        workingDays++;
      }

      bool hasShift = shiftDates.contains("${day.toString().padLeft(2, '0')}.${selectedMonth.toString().padLeft(2, '0')}.$selectedYear");


      // --- ОТРАБОТЕНИ ДНИ ---
      if (hasShift) {
        if (isWeekend || isHoliday) {
          workedWeekends++;
        } else {
          workedWeekdays++;
        }
      } 
      // --- СВОБОДНИ ДНИ ---
      else {
        if (isWeekend || isHoliday) {
          freeWeekends++;
        } else {
          freeWeekdays++;
        }
      }

      final shiftDate = "${day.toString().padLeft(2, '0')}.${selectedMonth.toString().padLeft(2, '0')}.$selectedYear";

      bool isSpecial = specialDays.containsKey(shiftDate);
      String? specialType = specialDays[shiftDate];

      if (isSpecial) {
        if (specialType == 'vacation') {
          vacationDays++;

          // Отпуск = отработен ден, но НЕ влиза в нормата
          workedWeekdays++;

          continue;
        }

        if (specialType == 'sick') {
          sickDays++;

          // Болничен = неработен ден, не влиза в нормата
          freeWeekdays++;

          continue;
        }
      }
    }

    // Общо работни дни
    totalWorkedDays = workedWeekdays + workedWeekends;

    // Общо свободни дни
    totalFreeDays = freeWeekdays + freeWeekends;

    // Норма (както беше)
    //workingDays = freeWeekdays + workedWeekdays;
    monthlyNorm = workingDays * 8;
    hourlyRate = 1055.82 / monthlyNorm;
  }


  Future<List<String>> _getHolidayDates(int year) async {
    final holidays = await DBHelper.instance.getHolidays(year);
    return holidays.map((e) => e['date'] as String).toList();
  }

  void _applyFilters() {
    List<Shift> filtered = monthlyShifts;

    if (filterTrain != null) {
      filtered = filtered.where((s) => s.trainNumber == filterTrain).toList();
    }

    if (filterLoco != null) {
      filtered = filtered.where((s) => s.locomotiveNumber == filterLoco).toList();
    }

    if (filterDestination != null && filterDestination!.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.destination.toLowerCase().contains(filterDestination!.toLowerCase())
      ).toList();
    }

    setState(() {
      // заменяме текущите смени с филтрираните
      monthlyShifts = filtered;
    });

    _calculateTotals();
  }

  Future<void> _exportExcel() async {
    final specialDays = await DBHelper.instance.getSpecialDaysForMonth(selectedMonth, selectedYear);

    vacationDays = specialDays.where((d) => d['type'] == 'vacation').length;
    sickDays = specialDays.where((d) => d['type'] == 'sick').length;


    try {
      await ExcelExportService().exportMonthlyReport(
        context: context,
        month: selectedMonth,
        year: selectedYear,
        shifts: monthlyShifts,
        totalHours: totalHours,
        totalNightHours: totalNightHours,
        totalNationalHours: totalNationalHours,
        totalKilometers: totalKilometers,
        totalNoService: totalNoService,
        workingDays: workingDays,
        holidayDays: holidayDays,
        monthlyNorm: monthlyNorm,
        vacationDays: vacationDays,
        sickDays: sickDays,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Грешка при експорта: $e")),
      );
    }
  }

  Future<void> _shareExcel() async {
    try {
      final path = await ExcelExportService().exportMonthlyReport(
        context: context,
        month: selectedMonth,
        year: selectedYear,
        shifts: monthlyShifts,
        totalHours: totalHours,
        totalNightHours: totalNightHours,
        totalNationalHours: totalNationalHours,
        totalKilometers: totalKilometers,
        totalNoService: totalNoService,
        workingDays: workingDays,
        holidayDays: holidayDays,
        monthlyNorm: monthlyNorm,
        vacationDays: vacationDays,
        sickDays: sickDays,
      );

      await ExcelExportService().shareFile(path);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Грешка при споделяне: $e")),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Статистика"),
      actions: [
        IconButton(
          icon: Icon(Icons.download),
          onPressed: _exportExcel,
        ),
        IconButton(
          icon: Icon(Icons.share),
          onPressed: _shareExcel,
        ),
      ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // MONTH & YEAR PICKER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text("Месец $m"),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => selectedMonth = v!);
                    _loadStatistics();
                  },
                ),
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
                    _loadStatistics();
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: filterTrain,
                    hint: Text("Филтър влак"),
                    items: availableTrains
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text("$t"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => filterTrain = v);
                      _applyFilters();
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<int>(
                    value: filterLoco,
                    hint: Text("Филтър локомотив"),
                    items: availableLocos
                        .map((l) => DropdownMenuItem(
                              value: l,
                              child: Text("$l"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => filterLoco = v);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            DropdownButton<String>(
              value: filterDestination,
              hint: Text("Филтър дестинация"),
              items: availableDestinations
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => filterDestination = v);
                _applyFilters();
              },
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  filterTrain = null;
                  filterLoco = null;
                  filterDestination = null;
                });
                _loadStatistics();
              },
              child: Text("Изчисти филтрите"),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [

                  // --- РАБОТНО ВРЕМЕ ---
                  ExpansionTile(
                    title: Text("Работно време", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildStat("Общо часове", totalHours),
                      _buildStat("Нощен труд", totalNightHours),
                      _buildStat("Национални", totalNationalHours),
                      _buildStat("Километри", "$totalKilometers"),
                      _buildStat("Без служба", "$totalNoService"),
                    ],
                  ),

                  // --- КАЛЕНДАРНИ ДНИ ---
                  ExpansionTile(
                    title: Text("Календарни дни", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildStat("Работни дни", "$workingDays"),
                      _buildStat("Почивни дни", "$holidayDays"),
                      _buildStat("Норма за месеца", "$monthlyNorm часа"),
                    ],
                  ),

                  // --- ОТРАБОТЕНИ ДНИ ---
                  ExpansionTile(
                    title: Text("Отработени дни", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildColoredStat("Общо", "$totalWorkedDays", Colors.blue),
                      _buildColoredStat("Делнични", "$workedWeekdays", Colors.green),
                      _buildColoredStat("Почивни", "$workedWeekends", Colors.orange),
                    ],
                  ),

                  // --- СВОБОДНИ ДНИ ---
                  ExpansionTile(
                    title: Text("Свободни дни", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildColoredStat("Общо", "$totalFreeDays", Colors.blueGrey),
                      _buildColoredStat("Делнични", "$freeWeekdays", Colors.green),
                      _buildColoredStat("Почивни", "$freeWeekends", Colors.orange),
                    ],
                  ),

                  // --- СРАВНЕНИЕ С НОРМАТА ---
                  ExpansionTile(
                    title: Text("Сравнение с нормата", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildColoredStat("Изпълнение", "${normPercent.toStringAsFixed(1)}%", 
                        normPercent >= 100 ? Colors.green : Colors.orange),
                      _buildColoredStat("Оставащи часове", "${remainingHours.toStringAsFixed(1)} ч.", 
                        remainingHours <= 0 ? Colors.green : Colors.red),
                    ],
                  ),

                  // --- ФИНАНСИ ---
                  ExpansionTile(
                    title: Text("Финанси", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    children: [
                      _buildStat("€ Километри", moneyKilometers.toStringAsFixed(2)),
                      _buildStat("€ Нощен труд", moneyNightHours.toStringAsFixed(2)),
                      _buildStat("€ Национално", moneyNationalHours.toStringAsFixed(2)),
                      _buildStat("€ Без служба", moneyNoService.toStringAsFixed(2)),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildColoredStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}