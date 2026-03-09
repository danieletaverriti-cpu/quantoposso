import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/boot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Boot.init();
  runApp(const QuantoPossoApp());
}