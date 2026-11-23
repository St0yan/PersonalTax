import 'package:flutter/material.dart';
import '../database/stations_db.dart';
import 'package:url_launcher/url_launcher.dart';

class StationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> station;

  const StationDetailsPage({super.key, required this.station});

  @override
  _StationDetailsPageState createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  late TextEditingController phoneController;

  Future<void> _call() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(
      text: widget.station['phone']?.toString() ?? '',
    );
  }

  Future<void> _save() async {
    final newPhone = phoneController.text.trim();

    await StationsDB.instance.updatePhone(
      widget.station['id'],
      newPhone,
    );

    Navigator.pop(context, newPhone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.station['name'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Съкращение: ${widget.station['abreviation']}",
                style: TextStyle(fontSize: 18)),

            SizedBox(height: 20),

            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Телефон",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              child: Text("Запази"),
            ),

            SizedBox(height: 10),

            if (phoneController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _call,
                icon: Icon(Icons.phone),
                label: Text("Обади се"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}