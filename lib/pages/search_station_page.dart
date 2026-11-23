import 'package:flutter/material.dart';
import '../database/stations_db.dart';
import 'station_details_page.dart';

class SearchStationPage extends StatefulWidget {
  const SearchStationPage({super.key});

  @override
  _SearchStationPageState createState() => _SearchStationPageState();
}

class _SearchStationPageState extends State<SearchStationPage> {
  List<Map<String, dynamic>> results = [];

  void _search(String text) async {
    if (text.isEmpty) {
      setState(() => results = []);
      return;
    }

    final data = await StationsDB.instance.searchStation(text);
    setState(() => results = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Търсене на гара")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Въведи име на гара",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),

          Expanded(
            child: results.isEmpty
                ? Center(child: Text("Няма резултати"))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final station = results[index];
                      return ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(station['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Съкращение: ${station['abreviation']}"),
                            if (station['phone'] != null && station['phone'].toString().isNotEmpty)
                              Text("Телефон: ${station['phone']}"),
                          ],
                        ),
                        onTap: () async {
                          final updatedPhone = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StationDetailsPage(station: station),
                            ),
                          );

                          if (updatedPhone != null) {
                            setState(() {
                              station['phone'] = updatedPhone;
                            });
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}