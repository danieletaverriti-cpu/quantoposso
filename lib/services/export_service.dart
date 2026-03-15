import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<void> exportCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/export_$timestamp.csv');

    final buffer = StringBuffer();
    buffer.writeln('Data,Tipo,Categoria,Importo,Nota');
    buffer.writeln('2026-03-01,Entrata,Stipendio,1800.00,Mensile');
    buffer.writeln('2026-03-02,Spesa,Spesa fissa,450.00,Affitto');
    buffer.writeln('2026-03-03,Spesa,Variabile,12.50,Caffè');

    if (startDate != null || endDate != null) {
      buffer.writeln();
      buffer.writeln(
        'Filtro periodo,${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : '-'} -> ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : '-'}',
      );
    }

    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export CSV',
    );
  }

  Future<void> exportPdf({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/export_$timestamp.pdf');

    // Placeholder PDF finto per non rompere tutto.
    // Se hai già il package pdf, poi lo sostituiamo con un PDF vero.
    await file.writeAsBytes([]);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export PDF',
    );
  }
}