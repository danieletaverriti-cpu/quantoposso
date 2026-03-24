import 'dart:async';
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

  static const String _appId = 'quantoposso';
  static const int _version = 1;
  static const int _maxAutoBackupHistory = 5;

  Timer? _debounce;

  Future<Directory> _docsDir() async {
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> _autoBackupDir() async {
    final dir = await _docsDir();
    final backupDir = Directory('${dir.path}/auto_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<File> _latestAutoBackupFile() async {
    final dir = await _autoBackupDir();
    return File('${dir.path}/latest_backup.json');
  }

  Map<String, dynamic> _buildBackupData(AppState state) {
    return {
      'app': _appId,
      'version': _version,
      'createdAt': DateTime.now().toIso8601String(),
      'expenses': state.expenses.map((e) => e.toMap()).toList(),
      'incomes': state.incomes.map((i) => i.toMap()).toList(),
      'fixed': state.fixed.map((f) => f.toMap()).toList(),
      'goals': state.goals.map((g) => g.toMap()).toList(),
      'settings': state.settings.toMap(),
      'profile': state.profile?.toMap(),
    };
  }

  String _prettyJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> exportBackup(AppState state) async {
    if (!state.isProActive) {
      throw Exception('Funzione disponibile solo con QuantoPosso PRO');
    }

    final data = _buildBackupData(state);
    final json = _prettyJson(data);

    final dir = await _docsDir();
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
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato backup non valido');
    }

    _validateBackup(decoded);

    await state.importBackup(decoded);
  }

  Future<void> autoBackup(AppState state) async {
    if (!state.isProActive) return;

    final data = _buildBackupData(state);
    final json = _prettyJson(data);

    final dir = await _autoBackupDir();

    final latestFile = File('${dir.path}/latest_backup.json');
    await latestFile.writeAsString(json, flush: true);

    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final historyFile = File('${dir.path}/auto_backup_$ts.json');
    await historyFile.writeAsString(json, flush: true);

    await _cleanupOldAutoBackups();
  }

  Future<void> autoBackupDebounced(AppState state) async {
    if (!state.isProActive) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () async {
      try {
        await autoBackup(state);
      } catch (_) {}
    });
  }

  Future<void> _cleanupOldAutoBackups() async {
    final dir = await _autoBackupDir();

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = f.path.split(Platform.pathSeparator).last;
          return name.startsWith('auto_backup_') && name.endsWith('.json');
        })
        .toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    for (final file in files.skip(_maxAutoBackupHistory)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  Future<bool> hasAutoBackup() async {
    final file = await _latestAutoBackupFile();
    return file.exists();
  }

  Future<DateTime?> lastAutoBackupDate() async {
    final file = await _latestAutoBackupFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final createdAt = decoded['createdAt']?.toString();
      if (createdAt == null || createdAt.isEmpty) return null;

      return DateTime.tryParse(createdAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> restoreAutoBackup(AppState state) async {
    if (!state.isProActive) {
      throw Exception('Funzione disponibile solo con QuantoPosso PRO');
    }

    final file = await _latestAutoBackupFile();

    if (!await file.exists()) {
      throw Exception('Nessun backup automatico trovato');
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato backup automatico non valido');
    }

    _validateBackup(decoded);

    await state.importBackup(decoded);
  }

  void _validateBackup(Map<String, dynamic> data) {
    if (data['app'] != _appId) {
      throw Exception('File non compatibile');
    }

    if (!data.containsKey('expenses') ||
        !data.containsKey('incomes') ||
        !data.containsKey('fixed') ||
        !data.containsKey('goals') ||
        !data.containsKey('settings')) {
      throw Exception('Backup incompleto');
    }
  }
}