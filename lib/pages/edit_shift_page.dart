import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';

class EditShiftPage extends StatefulWidget {
  final Shift shift;

  const EditShiftPage({super.key, required this.shift});

  @override
  _EditShiftPageState createState() => _EditShiftPageState();
}

class _EditShiftPageState extends State<EditShiftPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController dateController;
  late TextEditingController routeController;
  late TextEditingController locoController;
  late TextEditingController trainController;
  late TextEditingController destinationController;
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late TextEditingController kilometersController;
  late TextEditingController noServiceController;
  late TextEditingController nationalHoursController;

  @override
  void initState() {
    super.initState();

    dateController = TextEditingController(text: widget.shift.date);
    routeController = TextEditingController(text: widget.shift.routeNumber.toString());
    locoController = TextEditingController(text: widget.shift.locomotiveNumber.toString());
    trainController = TextEditingController(text: widget.shift.trainNumber.toString());
    destinationController = TextEditingController(text: widget.shift.destination);
    startTimeController = TextEditingController(text: widget.shift.startTime);
    endTimeController = TextEditingController(text: widget.shift.endTime);
    kilometersController = TextEditingController(text: widget.shift.kilometers.toString());
    noServiceController = TextEditingController(text: widget.shift.noService.toString());
    nationalHoursController = TextEditingController(text: widget.shift.nationalHours);
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

  // ---------- SAVE CHANGES ----------
  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final dateParts = dateController.text.split('.');
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    final nightHours = calculateNightHours(
      startTimeController.text,
      endTimeController.text,
    );

    final updatedShift = Shift(
      id: widget.shift.id,
      date: dateController.text,
      routeNumber: int.parse(routeController.text),
      locomotiveNumber: int.parse(locoController.text),
      trainNumber: int.parse(trainController.text),
      destination: destinationController.text,
      startTime: startTimeController.text,
      endTime: endTimeController.text,
      nightHours: nightHours,
      kilometers: int.parse(kilometersController.text),
      noService: int.parse(noServiceController.text),
      nationalHours: nationalHoursController.text,
      month: month,
      year: year,
    );

    await DBHelper.instance.updateShift(updatedShift);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Редактиране на смяна")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Дата"),
                  onTap: pickDate,
                ),

                TextFormField(
                  controller: routeController,
                  decoration: InputDecoration(labelText: "Номер на пътен лист"),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: locoController,
                  decoration: InputDecoration(labelText: "Номер на локомотив"),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: trainController,
                  decoration: InputDecoration(labelText: "Номер на влак"),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: destinationController,
                  decoration: InputDecoration(labelText: "Дестинация"),
                  textCapitalization: TextCapitalization.words,
                ),

                TextFormField(
                  controller: startTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Явяване"),
                  onTap: () => pickTime(startTimeController),
                ),

                TextFormField(
                  controller: endTimeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: "Освобождаване"),
                  onTap: () => pickTime(endTimeController),
                ),

                TextFormField(
                  controller: kilometersController,
                  decoration: InputDecoration(labelText: "Километри"),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: noServiceController,
                  decoration: InputDecoration(labelText: "Без служба"),
                  keyboardType: TextInputType.number,
                ),

                TextFormField(
                  controller: nationalHoursController,
                  decoration: InputDecoration(labelText: "Национални"),
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: saveChanges,
                  child: Text("Запази промените"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}