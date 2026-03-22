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
    if (!state.isProActive) {
      throw Exception('Funzione disponibile solo con QuantoPosso PRO');
    }

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
    if (!state.isProActive) {
      throw Exception('Funzione disponibile solo con QuantoPosso PRO');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    final data = jsonDecode(raw);

    if (data is! Map<String, dynamic>) {
      throw Exception('Formato backup non valido');
    }

    if (data['app'] != 'quantoposso') {
      throw Exception('File non compatibile');
    }

    if (!data.containsKey('expenses') ||
        !data.containsKey('incomes') ||
        !data.containsKey('fixed') ||
        !data.containsKey('goals') ||
        !data.containsKey('settings')) {
      throw Exception('Backup incompleto');
    }

    await state.importBackup(data);
  }

  Future<void> autoBackup(AppState state) async {
    if (!state.isProActive) return;

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
    final backupDir = Directory('${dir.path}/auto_backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/latest_backup.json');
    await file.writeAsString(json, flush: true);
  }

  Future<bool> hasAutoBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/auto_backups/latest_backup.json');
    return file.exists();
  }

  Future<void> restoreAutoBackup(AppState state) async {
    if (!state.isProActive) {
      throw Exception('Funzione disponibile solo con QuantoPosso PRO');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/auto_backups/latest_backup.json');

    if (!await file.exists()) {
      throw Exception('Nessun backup automatico trovato');
    }

    final raw = await file.readAsString();
    final data = jsonDecode(raw);

    if (data is! Map<String, dynamic>) {
      throw Exception('Formato backup automatico non valido');
    }

    if (data['app'] != 'quantoposso') {
      throw Exception('Backup automatico non compatibile');
    }

    await state.importBackup(data);
  }
}