import 'package:flutter/material.dart';

class TechnicianHome extends StatefulWidget {
  const TechnicianHome({super.key});

  @override
  State<TechnicianHome> createState() => _technicianHome();
}

class _technicianHome extends State<TechnicianHome> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(title: Text("Home"))),
    );
  }
}
