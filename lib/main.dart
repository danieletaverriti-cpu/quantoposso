import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/boot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Boot.init();
    runApp(const QuantoPossoApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('BOOT ERROR: $e'),
          ),
        ),
      ),
    );
  }
}