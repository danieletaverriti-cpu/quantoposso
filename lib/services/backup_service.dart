import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quantoposso/app/state.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<void> exportBackup(AppState state) async {
    final data = {
      'app': 'quantoposso',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'expenses': state.expenses.map((e) => e.toMap()).toList(),
      'incomes': state.incomes.map((i) => i.toMap()).toList(),
      'fixed': state.fixed.map((f) => f.toMap()).toList(),
      'goals': state.goals.map((g) => g.toMap()).toList(),
      'settings': state.settings.toMap(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/quantoposso_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    await file.writeAsString(json, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Backup Quanto Posso',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  Future<void> importBackup(AppState state) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(raw);

    await state.importBackup(data);
  }
}