import 'package:bazar_suez/markets/statistics/model/sales_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class SalesChart extends StatelessWidget {
  final List<SalesData> data;
  final bool isDaily;
  final Function(int index)? onTap;

  const SalesChart({
    super.key,
    required this.data,
    required this.isDaily,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<SalesData> chartData = isDaily && data.length > 15
        ? data.sublist(data.length - 15)
        : data;

    if (chartData.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للعرض'));
    }

    // ✅ لو فيه قيمة واحدة فقط، نعرض تصميم خاص
    if (chartData.length == 1) {
      final single = chartData.first;
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: AppColors.mainColor, size: 20),
              const SizedBox(height: 8),
              Text(
                '${single.value}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                single.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ لو فيه أكثر من نقطة نرسم الشارت العادي
    final values = chartData.map((e) => e.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();
    final interval = range == 0 ? 1 : range / 4;

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue + (range * 0.2),
          lineTouchData: LineTouchData(
            enabled: onTap != null,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black87,
            ),
            touchCallback:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (event is FlTapUpEvent &&
                  touchResponse != null &&
                  touchResponse.lineBarSpots != null) {
                final spot = touchResponse.lineBarSpots?.first;
                if (spot != null && onTap != null) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < chartData.length) {
                    onTap!(index);
                  }
                }
              }
            },
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval.toDouble(),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval == 0 ? 1 : interval.toDouble(),
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    final label = isDaily
                        ? chartData[index].label.replaceAll(RegExp(r'[^0-9]'), '')
                        : chartData[index].label;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < chartData.length; i++)
                  FlSpot(i.toDouble(), chartData[i].value),
              ],
              isCurved: true,
              color: AppColors.mainColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.mainColor.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
