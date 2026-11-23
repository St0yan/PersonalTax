import 'package:flutter/material.dart';
import 'package:personal_tax/widgets/add_shift_form.dart';
import '../database/db_helper.dart';
import '../widgets/add_absence.dart';
import '../pages/home_page.dart';

class SpecialDaysPage extends StatefulWidget {
  const SpecialDaysPage({super.key});

  @override
  _SpecialDaysPageState createState() => _SpecialDaysPageState();
}

class _SpecialDaysPageState extends State<SpecialDaysPage> {
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  List<Map<String, dynamic>> specialDaysThisMonth = [];

  Map<DateTime, List<Map<String, dynamic>>> absencesByDay = {};

  Future<void> loadAbsences() async {
    final data = await DBHelper.instance.getAbsencesForMonth(currentMonth, currentYear);

    absencesByDay.clear();

    for (var row in data) {
      final date = DateTime.parse(row['date']);
      absencesByDay.putIfAbsent(date, () => []).add(row);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadSpecialDaysThisMonth();
    //loadAbsences();
  }

  Future<void> loadSpecialDaysThisMonth() async {
    specialDaysThisMonth = await DBHelper.instance.getSpecialDaysForMonth(
      currentMonth,
      currentYear,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Добавяне на смяна , отпуск и болнични")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          AddShiftForm(
            onSaved: () async {
              await loadSpecialDaysThisMonth();
            },
          ),
          SizedBox(height: 20),
          AddAbsenceWidget(
            onAdd: (start, end, type) {
              addAbsenceRange(
                startDate: start,
                endDate: end,
                type: type == 'Отпуск' ? 'vacation' : 'sick',
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> addAbsenceRange({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  }) async {
    int addedDays = 0;

    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));

      // Пропускаме събота и неделя
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // Пропускаме празници и компенсаторни дни
      final key = "${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}";
      if (HomePage.globalHolidayKeys.contains(key)) {
        continue;
      }

      // Добавяме в базата
      if (type == 'vacation') {
        await DBHelper.instance.addVacationRange(date, 1);
      } else {
        await DBHelper.instance.addSickRange(date, 1);
      }

      addedDays++;
    }

    await loadSpecialDaysThisMonth();

    // SnackBar с броя реално добавени дни
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Добавени са $addedDays работни дни ($type)"),
        backgroundColor: type == 'vacation'
            ? Colors.blueAccent
            : Colors.orangeAccent,
      ),
    );
  }
}