import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quantoposso/app/state.dart';

import '../../services/export_service.dart';

enum ExportRangeType {
  currentCycle,
  lastMonth,
  custom,
}

class ExportScreen extends StatefulWidget {
  final AppState state;

  const ExportScreen({
    super.key,
    required this.state,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isLoading = false;
  String _selectedFormat = 'pdf';
  ExportRangeType _rangeType = ExportRangeType.currentCycle;

  DateTime? _startDate;
  DateTime? _endDate;

  static const Color _primaryBlue = Color(0xFF2F80FF);
  static const Color _primaryBlueDark = Color(0xFF2563EB);
  static const Color _cardDark = Color(0xFF2F3A4A);
  static const Color _softBg = Color(0xFFF7F8FC);
  static const Color _border = Color(0xFFE7ECF5);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _warningYellow = Color(0xFFFFD84D);
  static const Color _successGreen = Color(0xFF22C55E);

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  DateTime _firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _lastDayOfMonth(DateTime d) {
    final firstDayNextMonth =
        (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1));
  }

  Future<void> _export() async {
    DateTime? startDate;
    DateTime? endDate;

    final now = DateTime.now();

    switch (_rangeType) {
      case ExportRangeType.currentCycle:
        final cycleStartDay = 1;
        final today = DateTime(now.year, now.month, now.day);

        DateTime currentStart;
        DateTime currentEnd;

        if (today.day >= cycleStartDay) {
          currentStart = DateTime(today.year, today.month, cycleStartDay);
          currentEnd = (today.month == 12)
              ? DateTime(today.year + 1, 1, cycleStartDay).subtract(const Duration(days: 1))
              : DateTime(today.year, today.month + 1, cycleStartDay).subtract(const Duration(days: 1));
        } else {
          final prevMonth = (today.month == 1)
              ? DateTime(today.year - 1, 12, 1)
              : DateTime(today.year, today.month - 1, 1);

          currentStart = DateTime(prevMonth.year, prevMonth.month, cycleStartDay);
          currentEnd = DateTime(today.year, today.month, cycleStartDay).subtract(const Duration(days: 1));
        }

        startDate = currentStart;
        endDate = currentEnd;
        break;

      case ExportRangeType.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = _firstDayOfMonth(lastMonth);
        endDate = _lastDayOfMonth(lastMonth);
        break;

      case ExportRangeType.custom:
        if (_startDate == null || _endDate == null) {
          _showMessage('Seleziona una data iniziale e finale');
          return;
        }

        if (_endDate!.isBefore(_startDate!)) {
          _showMessage('La data finale non può essere prima di quella iniziale');
          return;
        }

        startDate = _startDate;
        endDate = _endDate;
        break;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedFormat == 'csv') {
        await ExportService.instance.exportCsv(
          state: widget.state,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        await ExportService.instance.exportPdf(
          state: widget.state,
          startDate: startDate,
          endDate: endDate,
        );
      }

      if (!mounted) return;
      _showMessage('Export completato con successo');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Errore durante l\'export: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _rangeLabel() {
    switch (_rangeType) {
      case ExportRangeType.currentCycle:
        return 'Ciclo attuale';
      case ExportRangeType.lastMonth:
        return 'Mese scorso';
      case ExportRangeType.custom:
        return '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
    }
  }

  String _formatLabel() => _selectedFormat.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Esporta dati',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _export,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(
                _isLoading ? 'Esportazione...' : 'Esporta dati',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            decoration: const BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crea e condividi i tuoi report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esporta i movimenti in CSV o PDF con un report ordinato e professionale.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Export rapido e condivisibile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _darkHeroCard(),
                  const SizedBox(height: 16),
                  _whiteSectionCard(
                    title: 'Formato file',
                    subtitle: 'Scegli come vuoi esportare i tuoi dati',
                    child: Row(
                      children: [
                        Expanded(
                          child: _formatCard(
                            title: 'CSV',
                            subtitle: 'Per Excel',
                            icon: Icons.grid_view_rounded,
                            accent: _successGreen,
                            selected: _selectedFormat == 'csv',
                            onTap: () {
                              setState(() {
                                _selectedFormat = 'csv';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formatCard(
                            title: 'PDF',
                            subtitle: 'Report premium',
                            icon: Icons.picture_as_pdf_rounded,
                            accent: _warningYellow,
                            selected: _selectedFormat == 'pdf',
                            onTap: () {
                              setState(() {
                                _selectedFormat = 'pdf';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _whiteSectionCard(
                    title: 'Periodo',
                    subtitle: 'Seleziona cosa vuoi esportare',
                    child: Column(
                      children: [
                        _rangeTile(
                          title: 'Ciclo attuale',
                          subtitle: 'Usa il ciclo stipendio impostato nell’app',
                          icon: Icons.calendar_month_rounded,
                          selected: _rangeType == ExportRangeType.currentCycle,
                          onTap: () {
                            setState(() {
                              _rangeType = ExportRangeType.currentCycle;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _rangeTile(
                          title: 'Mese scorso',
                          subtitle: 'Esporta i dati del mese precedente',
                          icon: Icons.history_rounded,
                          selected: _rangeType == ExportRangeType.lastMonth,
                          onTap: () {
                            setState(() {
                              _rangeType = ExportRangeType.lastMonth;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _rangeTile(
                          title: 'Intervallo personalizzato',
                          subtitle: 'Scegli data iniziale e finale',
                          icon: Icons.date_range_rounded,
                          selected: _rangeType == ExportRangeType.custom,
                          onTap: () {
                            setState(() {
                              _rangeType = ExportRangeType.custom;
                            });
                          },
                        ),
                        if (_rangeType == ExportRangeType.custom) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _dateCard(
                                  title: 'Da',
                                  value: _formatDate(_startDate),
                                  icon: Icons.event_available_rounded,
                                  onTap: _pickStartDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateCard(
                                  title: 'A',
                                  value: _formatDate(_endDate),
                                  icon: Icons.event_rounded,
                                  onTap: _pickEndDate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _summaryCard(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [_cardDark, Color(0xFF445064)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _cardDark.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Il tuo export è pronto da configurare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Formato selezionato: ${_formatLabel()}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _selectedFormat == 'csv' ? 0.55 : 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedFormat == 'csv' ? _successGreen : _warningYellow,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _formatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : _border,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  size: 18,
                  color: selected ? accent : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  selected ? 'Selezionato' : 'Tocca per scegliere',
                  style: TextStyle(
                    color: selected ? accent : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withOpacity(0.08) : const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primaryBlue : _border,
            width: selected ? 1.7 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? _primaryBlue.withOpacity(0.14) : const Color(0xFFEFF4FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? _primaryBlue : _textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? _primaryBlue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _primaryBlue, size: 20),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riepilogo export',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow('Formato', _formatLabel()),
          const SizedBox(height: 10),
          _summaryRow('Periodo', _rangeLabel()),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: _primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFormat == 'csv'
                        ? 'CSV è perfetto per Excel, filtri, formule e analisi manuali.'
                        : 'PDF crea un report premium con riepilogo, categorie e analisi della spesa.',
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}