import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/shift.dart';

class AddShiftForm extends StatefulWidget {
  final VoidCallback? onSaved; // извиква се след успешно добавяне

  const AddShiftForm({this.onSaved, super.key});

  @override
  State<AddShiftForm> createState() => _AddShiftFormState();
}

class _AddShiftFormState extends State<AddShiftForm> {
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

  DateTime? selectedDate;

  int safeParseInt(String value) {
    if (value.trim().isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

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

  Future<void> _saveShift() async {
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

    widget.onSaved?.call(); // уведомяваме родителя

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Смяната е добавена")),
    );

    _formKey.currentState!.reset();
    dateController.clear();
    routeController.clear();
    destinationController.clear();
    startTimeController.clear();
    endTimeController.clear();
    trainController.clear();
    locoController.clear();
    kilometersController.clear();
    noServiceController.clear();
    nationalHoursController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Добавяне на смяна",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold, 
                  )),
          
          const SizedBox(height: 16),

          // Дата
          TextFormField(
            controller: dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: "Дата",
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                selectedDate = picked;
                dateController.text =
                    "${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}";
              }
            },
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
          ),

          TextFormField(
            controller: startTimeController,
            decoration: InputDecoration(
              labelText: "Явяване",
              suffixIcon: Icon(Icons.access_time),
            ),
            validator: (v) => v!.isEmpty ? "Въведете начален час" : null,
            onTap: () => pickTime(startTimeController),
          ),
          
          TextFormField(
            controller: endTimeController,
            decoration: InputDecoration(
              labelText: "Освобождаване",
              suffixIcon: Icon(Icons.timer_off),
            ),
            validator: (v) => v!.isEmpty ? "Въведете краен час" : null,
            onTap: () => pickTime(endTimeController),
          ),
          
          TextFormField(
            controller: kilometersController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Километри",
              suffixIcon: Icon(Icons.route),
            ),
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

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("Запази смяната"),
              onPressed: _saveShift,
            ),
          ),
        ],
      ),
    );
  }
}