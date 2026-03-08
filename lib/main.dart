import 'package:flutter/material.dart';
import 'services/boot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Boot.init();
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("BOOT ERROR: $e")),
      ),
    ));
    return;
  }

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text("BOOT OK"),
      ),
    ),
  ));
}