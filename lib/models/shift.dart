class Shift {
  final int? id;

  final String date;              // dd.MM.yyyy
  final int routeNumber;          // номер на пътен лист
  final int locomotiveNumber;     // номер на локомотив
  final int trainNumber;          // номер на влак
  final String destination;       // дестинация

  final String startTime;         // явяване HH:mm
  final String endTime;           // освобождаване HH:mm
  final String nightHours;        // HH:mm (изчислява се автоматично)

  final int kilometers;           // километри
  final int noService;            // без служба
  final String nationalHours;     // HH:mm

  final int month;                // 1–12
  final int year;                 // 2024, 2025...

  Shift({
    this.id,
    required this.date,
    required this.routeNumber,
    required this.locomotiveNumber,
    required this.trainNumber,
    required this.destination,
    required this.startTime,
    required this.endTime,
    required this.nightHours,
    required this.kilometers,
    required this.noService,
    required this.nationalHours,
    required this.month,
    required this.year,
  });

  // ---------- SQLite: fromMap ----------
  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      date: map['date'],
      routeNumber: map['routeNumber'],
      locomotiveNumber: map['locomotiveNumber'],
      trainNumber: map['trainNumber'],
      destination: map['destination'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      nightHours: map['nightHours'],
      kilometers: map['kilometers'],
      noService: map['noService'],
      nationalHours: map['nationalHours'],
      month: map['month'],
      year: map['year'],
    );
  }

  // ---------- SQLite: toMap ----------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'routeNumber': routeNumber,
      'locomotiveNumber': locomotiveNumber,
      'trainNumber': trainNumber,
      'destination': destination,
      'startTime': startTime,
      'endTime': endTime,
      'nightHours': nightHours,
      'kilometers': kilometers,
      'noService': noService,
      'nationalHours': nationalHours,
      'month': month,
      'year': year,
    };
  }
}