import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../database/db_helper.dart';
import '../pages/edit_shift_page.dart';

class ShiftDetailsCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onUpdated;

  const ShiftDetailsCard({
    super.key,
    required this.shift,
    required this.onUpdated,
  });

  Widget buildRow(IconData icon, String label, String value, BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.7)),
          SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: color, fontSize: 15),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShift(BuildContext context) async {
    await DBHelper.instance.deleteShift(shift.id!);
    onUpdated();
  }

  Duration _calculateWorkDuration() {
    // startTime и endTime са във формат HH:mm
    final startParts = shift.startTime.split(':');
    final endParts = shift.endTime.split(':');

    final start = DateTime(0, 1, 1, int.parse(startParts[0]), int.parse(startParts[1]));
    var end = DateTime(0, 1, 1, int.parse(endParts[0]), int.parse(endParts[1]));

    // Ако смяната минава през полунощ → добавяме 1 ден
    if (end.isBefore(start)) {
      end = end.add(Duration(days: 1));
    }

    return end.difference(start);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;

    if (minutes == 0) return "$hours ч.";
    return "$hours ч. $minutes мин.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: Duration(milliseconds: 350),
      curve: Curves.easeOut,
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (theme.brightness != Brightness.dark)
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildRow(Icons.calendar_today, "Дата", shift.date, context),
          buildRow(Icons.list_alt, "Пътен лист", shift.routeNumber.toString(), context),
          buildRow(Icons.train_outlined, "Локомотив", shift.locomotiveNumber.toString(), context),
          buildRow(Icons.train, "Влак", shift.trainNumber.toString(), context),
          buildRow(Icons.location_on, "Дестинация", shift.destination, context),
          buildRow(Icons.access_time, "Явяване", shift.startTime, context),
          buildRow(Icons.timer_off, "Освобождаване", shift.endTime, context),
          buildRow(Icons.work_history, "Работно време", _formatDuration(_calculateWorkDuration()), context),
          buildRow(Icons.nights_stay, "Нощен труд", shift.nightHours, context),
          buildRow(Icons.route, "Километри", shift.kilometers.toString(), context),
          buildRow(Icons.block, "Без служба", shift.noService.toString(), context),
          buildRow(Icons.flag, "Национални", shift.nationalHours, context),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.edit, size: 18),
                label: Text("Редактирай"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditShiftPage(shift: shift),
                    ),
                  );
                  onUpdated();
                },
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.delete, size: 18),
                label: Text("Изтрий"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
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
          )
        ],
      ),
    );
  }
}