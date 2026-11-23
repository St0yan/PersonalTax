import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';

class AddShiftPage extends StatefulWidget {
  const AddShiftPage({super.key});

  @override
  _AddShiftPageState createState() => _AddShiftPageState();
}

class _AddShiftPageState extends State<AddShiftPage> {
  final _formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final routeController = TextEditingController();
  final locoController = TextEditingController();
  final trainController = TextEditingController();
  final destinationController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final kilometersController = TextEditingController();
  final noServiceController = TextEditingController();
  final nationalHoursController = TextEditingController();

  int safeParseInt(String value) {
    if (value.trim().isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  // ---------- NIGHT HOURS CALCULATOR ----------
  String calculateNightHours(String start, String end) {
    DateTime parse(String t) {
      final parts = t.split(':');
      return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    }

    DateTime startDt = parse(start);
    DateTime endDt = parse(end);

    if (endDt.isBefore(startDt)) {
      endDt = endDt.add(Duration(days: 1));
    }

    DateTime nightStart = DateTime(2000, 1, 1, 22, 0);
    DateTime nightEnd = DateTime(2000, 1, 2, 6, 0);

    DateTime overlapStart = startDt.isAfter(nightStart) ? startDt : nightStart;
    DateTime overlapEnd = endDt.isBefore(nightEnd) ? endDt : nightEnd;

    if (overlapEnd.isBefore(overlapStart)) {
      return "00:00";
    }

    Duration diff = overlapEnd.difference(overlapStart);

    int hours = diff.inHours;
    int minutes = diff.inMinutes % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  // ---------- TIME PICKER ----------
  Future<void> pickTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      controller.text =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  // ---------- DATE PICKER ----------
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      dateController.text =
          "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    }
  }

  // ---------- SAVE SHIFT ----------
  Future<void> saveShift() async {
    if (!_formKey.currentState!.validate()) return;

    final dateParts = dateController.text.split('.');
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    final nightHours = calculateNightHours(
      startTimeController.text,
      endTimeController.text,
    );

    final shift = Shift(
      date: dateController.text,
      routeNumber: safeParseInt(routeController.text),
      locomotiveNumber: safeParseInt(locoController.text),
      trainNumber: safeParseInt(trainController.text),
      destination: destinationController.text,
      startTime: startTimeController.text,
      endTime: endTimeController.text,
      nightHours: nightHours,
      kilometers: safeParseInt(kilometersController.text),
      noService: safeParseInt(noServiceController.text),
      nationalHours: nationalHoursController.text,
      month: month,
      year: year,
    );

    await DBHelper.instance.insertShift(shift);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Добавяне на смяна")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // DATE
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Дата", suffixIcon: Icon(Icons.calendar_today)),
                  onTap: pickDate,
                  validator: (v) => v!.isEmpty ? "Изберете дата" : null,
                ),

                TextFormField(
                  controller: routeController,
                  decoration: InputDecoration(labelText: "Номер на пътен лист", suffixIcon: Icon(Icons.list_alt)),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Въведете номер" : null,
                ),

                TextFormField(
                  controller: locoController,
                  decoration: InputDecoration(labelText: "Номер на локомотив", suffixIcon: Icon(Icons.train_outlined)),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: trainController,
                  decoration: InputDecoration(labelText: "Номер на влак", suffixIcon: Icon(Icons.train)),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: destinationController,
                  decoration: InputDecoration(labelText: "Дестинация", suffixIcon: Icon(Icons.location_on)),
                  textCapitalization: TextCapitalization.sentences,
                ),

                // START TIME
                TextFormField(
                  controller: startTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Явяване", suffixIcon: Icon(Icons.access_time)),
                  onTap: () => pickTime(startTimeController),
                ),

                // END TIME
                TextFormField(
                  controller: endTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Освобождаване", suffixIcon: Icon(Icons.timer_off)),
                  onTap: () => pickTime(endTimeController),
                ),

                TextFormField(
                  controller: kilometersController,
                  decoration: InputDecoration(labelText: "Километри", suffixIcon: Icon(Icons.route)),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: noServiceController,
                  decoration: InputDecoration(labelText: "Без служба", suffixIcon: Icon(Icons.block)),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: nationalHoursController,
                  decoration: InputDecoration(labelText: "Национални", suffixIcon: Icon(Icons.flag)),
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: saveShift,
                  child: Text("Запази"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}