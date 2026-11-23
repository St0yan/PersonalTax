import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';
import '../services/holiday_service.dart';
import '../widgets/shift_details_card.dart';
import '../widgets/animated_drawer_header.dart';
import 'search_station_page.dart';
import 'special_days_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
  static Set<String> globalHolidayKeys = {};
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Shift> _shiftsForSelectedDay = [];
  final List<String> _holidayDates = [];

  Map<DateTime, List<Shift>> _shiftsByDate = {};
  Map<DateTime, List<Map<String, dynamic>>> _specialDaysByDate = {};

  Set<String> _holidayKeys = {};
  List<Map<String, String>> _holidayInfo = [];

  String? _selectedHolidayName;

  String? _getHolidayName(String key) {
    for (var h in _holidayInfo) {
      if (h["key"] == key) return h["name"];
    }
    return null;
  }

  String? _getHolidayNameByDate(DateTime date) {
    final key = "${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}";
    for (var h in _holidayInfo) {
      if (h["key"] == key) return h["name"];
    }
    return null;
  }

  Shift? _selectedShift;

  Future<void> _loadSpecialDaysForMonth(DateTime month) async {
    final data = await DBHelper.instance.getSpecialDaysForMonth(
      month.month,
      month.year,
    );

    Map<DateTime, List<Map<String, dynamic>>> map = {};

    for (var row in data) {
      final parts = row['date'].split('.');
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      final key = DateTime(date.year, date.month, date.day);

      map.putIfAbsent(key, () => []).add(row);
    }

    setState(() {
      _specialDaysByDate = map;
    });
  }

  List<Map<String, dynamic>> groupAbsencePeriods(List<Map<String, dynamic>> days) {
    if (days.isEmpty) return [];

    days.sort((a, b) => a['date'].compareTo(b['date']));

    List<Map<String, dynamic>> periods = [];
    DateTime start = DateTime.parse(days.first['date']);
    DateTime prev = start;
    String type = days.first['type'];

    for (int i = 1; i < days.length; i++) {
      final current = DateTime.parse(days[i]['date']);

      if (current.difference(prev).inDays == 1 &&
          days[i]['type'] == type) {
        prev = current;
        continue;
      }

      periods.add({'start': start, 'end': prev, 'type': type});

      start = current;
      prev = current;
      type = days[i]['type'];
    }

    periods.add({'start': start, 'end': prev, 'type': type});

    return periods;
  }

  List<String> expandWithCompensatoryDays(List<String> holidays) {
    final Set<String> result = holidays.toSet();

    for (var iso in holidays) {
      final date = DateTime.parse(iso);

      if (date.weekday == DateTime.saturday) {
        final monday = date.add(Duration(days: 2));
        final mIso = "${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}";
        result.add(mIso);
      }

      if (date.weekday == DateTime.sunday) {
        final monday = date.add(Duration(days: 1));
        final mIso = "${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}";
        result.add(mIso);
      }
    }

    return result.toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _loadHolidays();
    _loadShiftsForDay(_selectedDay!);
    _loadAllShiftsForMonth(_focusedDay);
    _loadSpecialDaysForMonth(_focusedDay);
  }

  Future<void> _loadHolidays() async {
    final year = _focusedDay.year;

    final cached = await DBHelper.instance.getHolidays(year);

    if (cached.isEmpty) {
      await HolidayService().fetchAndCacheHolidays(year);
    }

    final holidays = await DBHelper.instance.getHolidays(year);

    // ISO списък
    final isoList = holidays.map((e) => e['date'] as String).toList();

    // Добавяме компенсаторните дни
    final expanded = expandWithCompensatoryDays(isoList);

    // Преобразуваме към DD.MM.YYYY + име
    final keys = <String>{};
    final info = <Map<String, String>>[];

    for (var h in holidays) {
      final iso = h['date'];
      final name = h['name'];

      final d = DateTime.parse(iso);
      final key = "${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}";

      info.add({"key": key, "name": name});
      keys.add(key);
    }

    // Добавяме компенсаторните дни (без име)
    for (var iso in expanded) {
      final d = DateTime.parse(iso);
      final key = "${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}";

      if (!keys.contains(key)) {
        keys.add(key);
        info.add({"key": key, "name": "Компенсаторен ден"});
      }
    }

    setState(() {
      _holidayKeys = keys;
      _holidayInfo = info;
      HomePage.globalHolidayKeys = keys;
    });
  }

  Future<void> _loadShiftsForDay(DateTime day) async {
    final formatted =
        "${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}";

    final shifts = await DBHelper.instance.getShiftsByDate(formatted);

    setState(() {
      _shiftsForSelectedDay = shifts;
    });
  }

  bool _isHoliday(DateTime day) {
    final iso = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _holidayDates.contains(iso);
  }

  Future<void> _loadAllShiftsForMonth(DateTime month) async {
    final shifts = await DBHelper.instance.getShiftsByMonth(month.month, month.year);

    Map<DateTime, List<Shift>> map = {};

    for (var s in shifts) {
      final parts = s.date.split('.');
      final d = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      map.putIfAbsent(d, () => []);
      map[d]!.add(s);
    }

    setState(() {
      _shiftsByDate = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Начало")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AnimatedDrawerHeader(),

            ListTile(
              leading: Icon(Icons.home),
              title: Text("Начало"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.add),
              title: Text("Добавяне"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SpecialDaysPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text("Статистика"),
              onTap: () {
                Navigator.pushNamed(context, '/stats');
              },
            ),

            ListTile(
              leading: Icon(Icons.search),
              title: Text("Гари"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchStationPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.info),
              title: Text("Информация"),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Настройки"),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,

            holidayPredicate: _isHoliday,

            eventLoader: (day) {
              return _shiftsForSelectedDay.where((s) {
                final parts = s.date.split('.');
                final d = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
                return d.year == day.year && d.month == day.month && d.day == day.day;
              }).toList();
            },

            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });

              final holidayName = _getHolidayNameByDate(selected);

              if (holidayName != null) {
                // 2) Показваме popup
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("Празничен ден"),
                      ],
                    ),
                    content: Text(
                      holidayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent.shade700,
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text("Затвори"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
              _loadShiftsForDay(selected).then((_) {
                setState(() {
                  _selectedShift = _shiftsForSelectedDay.isNotEmpty
                      ? _shiftsForSelectedDay.first
                      : null;
                });
              });
            },

            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadAllShiftsForMonth(focusedDay);
              _loadSpecialDaysForMonth(focusedDay);
            },

            calendarStyle: CalendarStyle(
              holidayDecoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

                final key = "${day.day.toString().padLeft(2,'0')}.${day.month.toString().padLeft(2,'0')}.${day.year}";
                final isHoliday = _holidayKeys.contains(key);
                final hasShift = _shiftsByDate.containsKey(DateTime(day.year, day.month, day.day));

                if (isHoliday && !hasShift) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                // --- ОТПУСК / БОЛНИЧЕН ---
                final special = _specialDaysByDate[DateTime(day.year, day.month, day.day)];

                if (special != null && special.isNotEmpty) {
                  final type = special.first['type'];

                  Color bg = type == 'vacation'
                      ? Colors.blue.shade200      // отпуск
                      : Colors.orange.shade300;   // болничен

                  Color textColor = type == 'vacation'
                      ? Colors.blue.shade900
                      : Colors.orange.shade900;

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                if(!isHoliday && hasShift) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                if(isHoliday && hasShift) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isWeekend ? Colors.redAccent : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isWeekend ? Colors.white : Colors.blueAccent,
                    ),
                  ),
                );
              },

              markerBuilder: (context, day, events) {
                final key = "${day.day.toString().padLeft(2,'0')}.${day.month.toString().padLeft(2,'0')}.${day.year}";

                final isHoliday = _holidayKeys.contains(key);
                final hasShift = _shiftsByDate.containsKey(DateTime(day.year, day.month, day.day));

                if (!isHoliday && !hasShift) return SizedBox.shrink();

                String tooltip = "";

                if (isHoliday) {
                  final name = _getHolidayName(key) ?? "Празничен ден";
                  tooltip = name;

                  if (hasShift) {
                    tooltip = "$name + смяна";
                  }
                } else if (hasShift) {
                  tooltip = "Смяна";
                }

                return Tooltip(
                  message: tooltip,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isHoliday)
                        Icon(Icons.celebration, size: 14, color: Colors.redAccent),

                      if (hasShift)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(Icons.train, size: 14, color: Colors.green.shade700),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Divider(),

          // --- ПОКАЗВАНЕ НА ОТПУСК/БОЛНИЧЕН ЗА ИЗБРАНИЯ ДЕН ---
          Builder(
            builder: (_) {
              final key = DateTime(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              );

              final special = _specialDaysByDate[key] ?? [];

              if (special.isEmpty) return SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Отпуск / Болничен:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  ...special.map((a) {
                    final type = a['type'] == 'vacation' ? 'Отпуск' : 'Болничен';
                    final icon = a['type'] == 'vacation'
                        ? Icons.beach_access
                        : Icons.medical_services;

                    return ListTile(
                      leading: Icon(icon,
                          color: a['type'] == 'vacation'
                              ? Colors.blue
                              : Colors.orange),
                      title: Text("$type – 8 часа"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DBHelper.instance.deleteSpecialDay(a['date']);
                          await _loadSpecialDaysForMonth(_focusedDay);
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _shiftsForSelectedDay.isEmpty
                  ? Center(
                      key: ValueKey("empty"),
                      child: Text("Няма смени за този ден"),
                    )
                  : _shiftsForSelectedDay.length == 1
                      ? ListView(
                          key: ValueKey("single"),
                          children: [
                            ShiftDetailsCard(
                              shift: _shiftsForSelectedDay.first,
                              onUpdated: () {
                                _loadShiftsForDay(_selectedDay!);
                                setState(() {});
                              },
                            ),
                          ],
                        )
                  : ListView(
                      key: ValueKey("multi_${_shiftsForSelectedDay.length}"),
                      children: _shiftsForSelectedDay.map((shift) {
                        return ExpansionTile(
                          title: Text(
                            "Смяна: ${shift.startTime} → ${shift.endTime}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            ShiftDetailsCard(
                              shift: shift,
                              onUpdated: () {
                                _loadShiftsForDay(_selectedDay!);
                                setState(() {});
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/add')
              .then((_) => _loadShiftsForDay(_selectedDay!));
        },
      ),
    );
  }
}