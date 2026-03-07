import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthOverviewChart extends StatelessWidget {
  final double income;
  final double spent;
  final double saving;
  final double remaining;

  const MonthOverviewChart({
    super.key,
    required this.income,
    required this.spent,
    required this.saving,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    final values = <double>[income, spent, saving, remaining];
    final maxY = (values.reduce((a, b) => a > b ? a : b)).clamp(1, double.infinity);

    BarChartGroupData g(int x, double y) => BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: y.clamp(0, double.infinity),
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = ['Entrate', 'Uscite', 'Risparmio', 'Rimanente'];
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[i], style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final labels = ['Entrate', 'Uscite', 'Risparmio', 'Rimanente'];
                    return BarTooltipItem(
                      '${labels[group.x]}\n${euro.format(rod.toY)}',
                      const TextStyle(fontWeight: FontWeight.w700),
                    );
                  },
                ),
              ),
              barGroups: [
                g(0, income),
                g(1, spent),
                g(2, saving),
                g(3, remaining),
              ],
            ),
          ),
        ),
      ],
    );
  }
}