import 'package:flutter/material.dart';

class AddAbsenceWidget extends StatefulWidget {
  final Function(DateTime start, DateTime end, String type) onAdd;

  const AddAbsenceWidget({super.key, required this.onAdd});

  @override
  State<AddAbsenceWidget> createState() => _AddAbsenceWidgetState();
}

class _AddAbsenceWidgetState extends State<AddAbsenceWidget> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedType = 'Отпуск';

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Тип отсъствие
        DropdownButton<String>(
          value: selectedType,
          items: ['Отпуск', 'Болничен'].map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => selectedType = value!);
          },
        ),

        const SizedBox(height: 12),

        // Избор на начална дата
        Row(
          children: [
            Expanded(
              child: Text(startDate == null
                  ? 'Начална дата: не е избрана'
                  : 'Начална дата: ${startDate!.toLocal().toString().split(" ")[0]}'),
            ),
            ElevatedButton(
              onPressed: pickStartDate,
              child: const Text('Избери'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Избор на крайна дата
        Row(
          children: [
            Expanded(
              child: Text(endDate == null
                  ? 'Крайна дата: не е избрана'
                  : 'Крайна дата: ${endDate!.toLocal().toString().split(" ")[0]}'),
            ),
            ElevatedButton(
              onPressed: startDate == null ? null : pickEndDate,
              child: const Text('Избери'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            if (startDate != null && endDate != null) {
              widget.onAdd(startDate!, endDate!, selectedType);

              // --- ПОКАЗВАМЕ СЪОБЩЕНИЕ ---
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedType == 'Отпуск'
                        ? 'Отпускът е добавен успешно!'
                        : 'Болничният е добавен успешно!',
                  ),
                  backgroundColor: selectedType == 'Отпуск'
                      ? Colors.blueAccent
                      : Colors.orangeAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('Добави'),
        ),
      ],
    );
  }
}