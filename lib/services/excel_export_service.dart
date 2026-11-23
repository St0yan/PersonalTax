import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../models/shift.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  Future<void> requestStoragePermissions() async {
    final status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath();
  }

  Future<String?> askFileName(BuildContext context) async {
    final controller = TextEditingController(text: "Отчет");

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Име на файла"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: "Въведи име"),
          ),
          actions: [
            TextButton(
              child: Text("Отказ"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
    );
  }

  Future<String> exportMonthlyReport({
    required BuildContext context,
    required int month,
    required int year,
    required List<Shift> shifts,
    required String totalHours,
    required String totalNightHours,
    required String totalNationalHours,
    required int totalKilometers,
    required int totalNoService,
    required int workingDays,
    required int holidayDays,
    required int monthlyNorm,
    required int vacationDays,
    required int sickDays,
  }) async {
    await requestStoragePermissions();

    // 1) Избор на директория
    final directoryPath = await pickDirectory();
    if (directoryPath == null) {
      throw Exception("Не е избрана директория");
    }

    // 2) Избор на име
    final fileName = await askFileName(context);
    if (fileName == null || fileName.trim().isEmpty) {
      throw Exception("Не е въведено име на файла");
    }

    final excel = Excel.createExcel();
    final sheet = excel['Отчет'];

    // Header
    sheet.appendRow([
      TextCellValue("Дата"),
      TextCellValue("Пътен лист"),
      TextCellValue("Локомотив"),
      TextCellValue("Влак"),
      TextCellValue("Дестинация"),
      TextCellValue("Явяване"),
      TextCellValue("Освобождаване"),
      TextCellValue("Нощен труд"),
      TextCellValue("Километри"),
      TextCellValue("Без служба"),
      TextCellValue("Национални"),
    ]);

    // Data rows
    for (var s in shifts) {
      sheet.appendRow([
        TextCellValue(s.date),
        IntCellValue(s.routeNumber),
        IntCellValue(s.locomotiveNumber),
        IntCellValue(s.trainNumber),
        TextCellValue(s.destination),
        TextCellValue(s.startTime),
        TextCellValue(s.endTime),
        TextCellValue(s.nightHours),
        IntCellValue(s.kilometers),
        IntCellValue(s.noService),
        TextCellValue(s.nationalHours),
      ]);
    }

    final boldCentered = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Summary
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue("Отпуск:"), TextCellValue(vacationDays.toString())]);
    sheet.appendRow([TextCellValue("Болничен:"), TextCellValue(sickDays.toString())]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue( "Общо")]);
    sheet.appendRow([TextCellValue("Часове"), TextCellValue(totalHours)]);
    sheet.appendRow([TextCellValue("Нощен труд"), TextCellValue(totalNightHours)]);
    sheet.appendRow([TextCellValue("Национални"), TextCellValue(totalNationalHours)]);
    sheet.appendRow([TextCellValue("Километри"), IntCellValue(totalKilometers)]);
    sheet.appendRow([TextCellValue("Без служба"), IntCellValue(totalNoService)]);
    //sheet.appendRow([TextCellValue("Работни дни"), IntCellValue(workingDays)]);
    //sheet.appendRow([TextCellValue("Почивни дни"), IntCellValue(holidayDays)]);
    //sheet.appendRow([TextCellValue("Норма за месеца"), TextCellValue("$monthlyNorm часа")]);

    void boldResult(int rowIndex) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .cellStyle = boldCentered;
    }

    final startRow = sheet.maxRows - 9; // броим от края нагоре

    boldResult(startRow + 1); // Отпуск
    boldResult(startRow + 2); // Болничен
    // празен ред
    // "Общо" няма резултат → пропускаме
    boldResult(startRow + 4); // Часове
    boldResult(startRow + 5); // Нощен труд
    boldResult(startRow + 6); // Национални
    boldResult(startRow + 7); // Километри
    boldResult(startRow + 8); // Без служба

    // 3) Запис
    excel.delete(excel.getDefaultSheet()!); // Премахваме автоматично създадения лист
    final filePath = "$directoryPath/$fileName.xlsx";
    final fileBytes = excel.encode();
    final file = File(filePath);
    await file.writeAsBytes(fileBytes!);

    // 4) Автоматично отваряне
    await OpenFilex.open(filePath);

    // 5) SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Файлът е записан успешно:\n$filePath")),
    );

    return filePath;
  }

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: "Месечен отчет",
    );
  }
}