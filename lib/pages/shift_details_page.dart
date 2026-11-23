import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../database/db_helper.dart';
import 'edit_shift_page.dart';

class ShiftDetailsPage extends StatelessWidget {
  final Shift shift;

  const ShiftDetailsPage({super.key, required this.shift});

  Future<void> _deleteShift(BuildContext context) async {
    await DBHelper.instance.deleteShift(shift.id!);
    Navigator.pop(context); // връща към предишния екран
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Детайли за смяна"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditShiftPage(shift: shift),
                ),
              ).then((_) {
                Navigator.pop(context); // затваря детайлите след редакция
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Изтриване"),
                  content: Text("Сигурни ли сте, че искате да изтриете тази смяна?"),
                  actions: [
                    TextButton(
                      child: Text("Отказ"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text("Изтрий"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _deleteShift(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildRow("Дата", shift.date),
            buildRow("Пътен лист", shift.routeNumber.toString()),
            buildRow("Локомотив", shift.locomotiveNumber.toString()),
            buildRow("Влак", shift.trainNumber.toString()),
            buildRow("Дестинация", shift.destination),
            buildRow("Явяване", shift.startTime),
            buildRow("Освобождаване", shift.endTime),
            buildRow("Нощен труд", shift.nightHours),
            buildRow("Километри", shift.kilometers.toString()),
            buildRow("Без служба", shift.noService.toString()),
            buildRow("Национални", shift.nationalHours),
            buildRow("Месец", shift.month.toString()),
            buildRow("Година", shift.year.toString()),
          ],
        ),
      ),
    );
  }
}