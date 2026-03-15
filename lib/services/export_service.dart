import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quantoposso/app/state.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 2,
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');

  Future<void> exportCsv({
    required AppState state,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final movements = await _loadMovements(
      state: state,
      startDate: startDate,
      endDate: endDate,
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = _fileDateFormat.format(DateTime.now());
    final file = File('${dir.path}/resconto_quantoposso$timestamp.csv');

    final buffer = StringBuffer();
    buffer.writeln('Data,Tipo,Categoria,Descrizione,Importo');

    for (final movement in movements) {
      buffer.writeln(
        '${_escapeCsv(_dateFormat.format(movement.date))},'
        '${_escapeCsv(movement.type.label)},'
        '${_escapeCsv(movement.category)},'
        '${_escapeCsv(movement.description)},'
        '${movement.amount.toStringAsFixed(2)}',
      );
    }

    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export CSV Quanto Posso',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  Future<void> exportPdf({
    required AppState state,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final movements = await _loadMovements(
      state: state,
      startDate: startDate,
      endDate: endDate,
    );

    final report = _buildReportData(
      movements,
      startDate: startDate,
      endDate: endDate,
    );

    final pdf = pw.Document();
    final logo = await _loadLogoProvider();

    final baseFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
          ),
        ),
        build: (context) => [
          _buildHeader(report, logo),
          pw.SizedBox(height: 18),
          _buildHeroCard(report),
          pw.SizedBox(height: 18),
          _buildSummaryCards(report),
          pw.SizedBox(height: 18),
          _buildInsights(report),
          pw.SizedBox(height: 18),
          _buildCategorySection(report),
          pw.SizedBox(height: 18),
          _buildTopCategories(report),
          pw.SizedBox(height: 18),
          _buildMovementsTable(report),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = _fileDateFormat.format(DateTime.now());
    final file = File('${dir.path}/quantopossov2_report_$timestamp.pdf');

    await file.writeAsBytes(await pdf.save(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reseoconto PDF Quanto Posso',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  Future<List<_ExportMovement>> _loadMovements({
    required AppState state,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final all = <_ExportMovement>[];

    for (final e in state.expenses) {
      all.add(
        _ExportMovement(
          date: e.date,
          type: _ExportMovementType.expense,
          category: e.category.trim().isEmpty ? 'Altro' : e.category,
          description: e.note.trim().isEmpty ? 'Spesa' : e.note,
          amount: e.amount,
        ),
      );
    }

    for (final i in state.incomes) {
      all.add(
        _ExportMovement(
          date: i.date,
          type: _ExportMovementType.income,
          category: i.category.trim().isEmpty ? 'Entrate' : i.category,
          description: i.note.trim().isEmpty ? 'Entrata' : i.note,
          amount: i.amount,
        ),
      );
    }

    final filtered = all.where((m) {
      final afterStart = startDate == null ||
          !m.date.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          );

      final beforeEnd = endDate == null ||
          !m.date.isAfter(
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          );

      return afterStart && beforeEnd;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  _ExportReportData _buildReportData(
    List<_ExportMovement> movements, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final incomes = movements
        .where((m) => m.type == _ExportMovementType.income)
        .toList();

    final expenses = movements
        .where((m) => m.type == _ExportMovementType.expense)
        .toList();

    final totalIncome = incomes.fold<double>(0, (sum, m) => sum + m.amount);
    final totalExpense = expenses.fold<double>(0, (sum, m) => sum + m.amount);
    final balance = totalIncome - totalExpense;

    final Map<String, double> expensesByCategory = {};
    final Map<String, int> expenseCountByCategory = {};

    for (final movement in expenses) {
      final category =
          movement.category.trim().isEmpty ? 'Altro' : movement.category;
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + movement.amount;
      expenseCountByCategory[category] =
          (expenseCountByCategory[category] ?? 0) + 1;
    }

    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories
        .map(
          (entry) => _CategoryAmount(
            category: entry.key,
            amount: entry.value,
            count: expenseCountByCategory[entry.key] ?? 0,
          ),
        )
        .toList();

    final mainCategory = topCategories.isNotEmpty ? topCategories.first : null;
    final mainCategoryPercent = (mainCategory != null && totalExpense > 0)
        ? (mainCategory.amount / totalExpense) * 100
        : 0.0;

    final top3Total = topCategories
        .take(3)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final top3Percent =
        totalExpense > 0 ? (top3Total / totalExpense) * 100 : 0.0;

    final averageExpense =
        expenses.isEmpty ? 0.0 : totalExpense / expenses.length;

    return _ExportReportData(
      generatedAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      movements: movements,
      incomes: incomes,
      expenses: expenses,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      expensesByCategory: topCategories,
      mainCategory: mainCategory,
      mainCategoryPercent: mainCategoryPercent,
      averageExpense: averageExpense,
      top3Percent: top3Percent,
    );
  }

  Future<pw.ImageProvider?> _loadLogoProvider() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildHeader(_ExportReportData report, pw.ImageProvider? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(
            width: 44,
            height: 44,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 12,
              verticalRadius: 12,
              child: pw.Image(logo, fit: pw.BoxFit.cover),
            ),
          )
        else
          pw.Container(
            width: 44,
            height: 44,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2F80FF'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'QP',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Quanto Posso',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1F2937'),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Report spese premium',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Periodo',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _periodLabel(report.startDate, report.endDate),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1F2937'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHeroCard(_ExportReportData report) {
    final balanceColor =
        report.balance >= 0 ? PdfColor.fromHex('#22C55E') : PdfColor.fromHex('#EF4444');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(22),
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromHex('#2F3A4A'),
            PdfColor.fromHex('#445064'),
          ],
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Questo è il pdf Nuovo',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Questo report evidenzia dove spendi di più, come sono distribuite le uscite e quali categorie pesano maggiormente nel periodo selezionato.',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#D8E1EE'),
              fontSize: 10.5,
              lineSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#5A667A'),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Saldo periodo',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10.5,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  _currency.format(report.balance),
                  style: pw.TextStyle(
                    color: balanceColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCards(_ExportReportData report) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _summaryCard(
            title: 'Entrate',
            value: _currency.format(report.totalIncome),
            color: PdfColor.fromHex('#22C55E'),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            title: 'Spese',
            value: _currency.format(report.totalExpense),
            color: PdfColor.fromHex('#F59E0B'),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            title: 'Saldo',
            value: _currency.format(report.balance),
            color: PdfColor.fromHex('#2F80FF'),
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: PdfColor.fromHex('#E7ECF5')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
  width: 12,
  height: 12,
  decoration: pw.BoxDecoration(
    color: color,
    borderRadius: pw.BorderRadius.circular(4),
  ),
),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F2937'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInsights(_ExportReportData report) {
    final insights = <String>[
      if (report.mainCategory != null)
        'La categoria con la spesa più alta è ${report.mainCategory!.category}, con ${_currency.format(report.mainCategory!.amount)}, pari al ${report.mainCategoryPercent.toStringAsFixed(1)}% delle uscite.',
      'Hai registrato ${report.movements.length} movimenti nel periodo selezionato, di cui ${report.expenses.length} uscite e ${report.incomes.length} entrate.',
      if (report.expenses.isNotEmpty)
        'La spesa media per movimento è di ${_currency.format(report.averageExpense)}.',
      if (report.expensesByCategory.isNotEmpty)
        'Le prime 3 categorie coprono il ${report.top3Percent.toStringAsFixed(1)}% del totale spese.',
      if (report.balance >= 0)
        'Nel periodo selezionato il saldo resta positivo, con una differenza di ${_currency.format(report.balance)} tra entrate e uscite.'
      else
        'Nel periodo selezionato le uscite superano le entrate di ${_currency.format(report.balance.abs())}.',
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F3F7FF'),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Insight automatici',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F2937'),
            ),
          ),
          pw.SizedBox(height: 10),
          ...insights.map(
            (text) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                 pw.Container(
  margin: const pw.EdgeInsets.only(top: 4),
  width: 6,
  height: 6,
  decoration: pw.BoxDecoration(
    color: PdfColor.fromHex('#2F80FF'),
    borderRadius: pw.BorderRadius.circular(2),
  ),
),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      text,
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        lineSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategorySection(_ExportReportData report) {
    final categories = report.expensesByCategory.take(6).toList();
    final total = categories.fold<double>(0, (sum, e) => sum + e.amount);
    final maxValue = categories.isEmpty
        ? 1.0
        : categories.map((e) => e.amount).reduce(math.max);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: PdfColor.fromHex('#E7ECF5')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Distribuzione spese',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F2937'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Le categorie principali del periodo selezionato',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
          pw.SizedBox(height: 18),
          if (categories.isEmpty)
            pw.Text(
              'Nessuna spesa disponibile per generare il grafico.',
              style: pw.TextStyle(
                fontSize: 10.5,
                color: PdfColor.fromHex('#6B7280'),
              ),
            )
          else ...[
            for (int i = 0; i < categories.length; i++)
              _categoryBarRow(
                item: categories[i],
                color: _chartColors[i % _chartColors.length],
                maxValue: maxValue,
                totalValue: total,
              ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FBFF'),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
  width: 12,
  height: 12,
  decoration: pw.BoxDecoration(
    color: PdfColor.fromHex('#2F80FF'),
    borderRadius: pw.BorderRadius.circular(4),
  ),
),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      report.mainCategory == null
                          ? 'Nessuna categoria dominante rilevata.'
                          : 'Categoria dominante: ${report.mainCategory!.category}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1F2937'),
                      ),
                    ),
                  ),
                  if (report.mainCategory != null)
                    pw.Text(
                      '${report.mainCategoryPercent.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2F80FF'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _categoryBarRow({
    required _CategoryAmount item,
    required PdfColor color,
    required double maxValue,
    required double totalValue,
  }) {
    final widthFactor = maxValue > 0 ? item.amount / maxValue : 0.0;
    final percent = totalValue > 0 ? (item.amount / totalValue) * 100 : 0.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
  width: 10,
  height: 10,
  decoration: pw.BoxDecoration(
    color: color,
    borderRadius: pw.BorderRadius.circular(3),
  ),
),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  item.category,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1F2937'),
                  ),
                ),
              ),
              pw.Text(
                _currency.format(item.amount),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1F2937'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EEF2F7'),
                    borderRadius: pw.BorderRadius.circular(999),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: 280 * widthFactor,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 42,
                child: pw.Text(
                  '${percent.toStringAsFixed(1)}%',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColor.fromHex('#6B7280'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopCategories(_ExportReportData report) {
    final top = report.expensesByCategory.take(5).toList();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: PdfColor.fromHex('#E7ECF5')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Top categorie',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F2937'),
            ),
          ),
          pw.SizedBox(height: 12),
          if (top.isEmpty)
            pw.Text(
              'Nessuna categoria disponibile.',
              style: pw.TextStyle(
                fontSize: 10.5,
                color: PdfColor.fromHex('#6B7280'),
              ),
            )
          else
            ...top.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final color = _chartColors[entry.key % _chartColors.length];

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F9FBFF'),
                    borderRadius: pw.BorderRadius.circular(14),
                  ),
                  child: pw.Row(
                    children: [
                     pw.Container(
  width: 24,
  height: 24,
  alignment: pw.Alignment.center,
  decoration: pw.BoxDecoration(
    color: color,
    borderRadius: pw.BorderRadius.circular(8),
  ),
  child: pw.Text(
    '$rank',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.category,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#1F2937'),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '${item.count} movimenti',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                color: PdfColor.fromHex('#6B7280'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        _currency.format(item.amount),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1F2937'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  pw.Widget _buildMovementsTable(_ExportReportData report) {
    final rows = report.movements.take(30).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dettaglio movimenti',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1F2937'),
          ),
        ),
        pw.SizedBox(height: 10),
        if (rows.isEmpty)
          pw.Text(
            'Nessun movimento disponibile.',
            style: pw.TextStyle(
              fontSize: 10.5,
              color: PdfColor.fromHex('#6B7280'),
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E7ECF5'),
              width: 0.6,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(2.2),
              4: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F3F7FF'),
                ),
                children: [
                  _tableHeader('Data'),
                  _tableHeader('Tipo'),
                  _tableHeader('Categoria'),
                  _tableHeader('Descrizione'),
                  _tableHeader('Importo'),
                ],
              ),
              ...rows.map((m) {
                final isIncome = m.type == _ExportMovementType.income;

                return pw.TableRow(
                  children: [
                    _tableCell(_dateFormat.format(m.date)),
                    _tableCell(m.type.label),
                    _tableCell(m.category),
                    _tableCell(m.description),
                    _tableCell(
                      _currency.format(m.amount),
                      textColor: isIncome
                          ? PdfColor.fromHex('#16A34A')
                          : PdfColor.fromHex('#B45309'),
                      alignRight: true,
                      bold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        if (report.movements.length > 30) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Nel report sono mostrati i primi 30 movimenti ordinati per data.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1F2937'),
        ),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    PdfColor? textColor,
    bool alignRight = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: textColor ?? PdfColor.fromHex('#374151'),
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _periodLabel(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return 'Periodo corrente';
    }
    if (startDate != null && endDate != null) {
      return '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
    }
    if (startDate != null) {
      return 'Da ${_dateFormat.format(startDate)}';
    }
    return 'Fino al ${_dateFormat.format(endDate!)}';
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static final List<PdfColor> _chartColors = [
    PdfColor.fromHex('#2F80FF'),
    PdfColor.fromHex('#22C55E'),
    PdfColor.fromHex('#F59E0B'),
    PdfColor.fromHex('#A855F7'),
    PdfColor.fromHex('#EF4444'),
    PdfColor.fromHex('#06B6D4'),
  ];
}

enum _ExportMovementType {
  income,
  expense;

  String get label {
    switch (this) {
      case _ExportMovementType.income:
        return 'Entrata';
      case _ExportMovementType.expense:
        return 'Spesa';
    }
  }
}

class _ExportMovement {
  final DateTime date;
  final _ExportMovementType type;
  final String category;
  final String description;
  final double amount;

  _ExportMovement({
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
  });
}

class _CategoryAmount {
  final String category;
  final double amount;
  final int count;

  _CategoryAmount({
    required this.category,
    required this.amount,
    required this.count,
  });
}

class _ExportReportData {
  final DateTime generatedAt;
  final DateTime? startDate;
  final DateTime? endDate;

  final List<_ExportMovement> movements;
  final List<_ExportMovement> incomes;
  final List<_ExportMovement> expenses;

  final double totalIncome;
  final double totalExpense;
  final double balance;

  final List<_CategoryAmount> expensesByCategory;
  final _CategoryAmount? mainCategory;
  final double mainCategoryPercent;
  final double averageExpense;
  final double top3Percent;

  _ExportReportData({
    required this.generatedAt,
    required this.startDate,
    required this.endDate,
    required this.movements,
    required this.incomes,
    required this.expenses,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expensesByCategory,
    required this.mainCategory,
    required this.mainCategoryPercent,
    required this.averageExpense,
    required this.top3Percent,
  });
}