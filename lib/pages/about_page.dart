import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("За приложението"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // HEADER
            Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/about_logo.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Лични сметки",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Версия 1.0.0",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // ABOUT APP
            Text(
              "За приложението",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Това приложение е създадено за управление на работни смени, "
              "включително записване на смени, изчисляване на нощен труд, "
              "генериране на статистики и изготвяне на месечни отчети.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 30),

            // ABOUT CREATOR
            Text(
              "Създател",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Приложението е разработено от Стоян Димитров (Пиерса), "
              "като се стреми да улесни изготвянето на лични сметки "
              "на локомотивни машинисти и други професии с работни смени.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 30),

            // CONTACT
            Text(
              "Контакт",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Email: St0yan@abv.bg\n",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 40),

            Center(
              child: Text(
                "© ${DateTime.now().year} Shift Manager",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}