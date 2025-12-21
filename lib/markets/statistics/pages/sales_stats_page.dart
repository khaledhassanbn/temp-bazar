import 'package:bazar_suez/markets/statistics/viewModel/sales_stats_view_model.dart';
import 'package:bazar_suez/markets/statistics/model/sales_data_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/my_order/pages/PastOrdersPage.dart';

import '../widgets/header.dart';
import '../widgets/tab_button.dart';
import '../widgets/sales_chart.dart';
import '../widgets/sales_row.dart';

class SalesStatsPage extends StatelessWidget {
  const SalesStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SalesStatsViewModel(),
      child: const _SalesStatsView(),
    );
  }
}

class _SalesStatsView extends StatelessWidget {
  const _SalesStatsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SalesStatsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(title: "إحصائيات المتجر"),
            const SizedBox(height: 12),

            // ✅ Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TabButton(
                      title: "يوميًا",
                      selected: vm.isDaily,
                      onTap: () => vm.toggleView(true),
                      onPickDate: () => _showMonthYearPicker(context, vm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TabButton(
                      title: "شهريًا",
                      selected: !vm.isDaily,
                      onTap: () => vm.toggleView(false),
                      onPickDate: () => _showYearPicker(context, vm),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(),
              )
            else if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            else if (vm.salesData.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "لا توجد بيانات متاحة للفترة المحددة",
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              SalesChart(
                data: vm.salesData,
                isDaily: vm.isDaily,
                onTap: (index) => _handleChartTap(context, vm, index),
              ),

            const SizedBox(height: 24),

            // ✅ الكروت
            Expanded(
              child: vm.isLoading || vm.errorMessage != null
                  ? const SizedBox.shrink()
                  : vm.salesData.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد بيانات",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: vm.salesData.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = vm.salesData[index];
                        final date = vm.isDaily
                            ? "${vm.selectedYear}-${vm.selectedMonth.toString().padLeft(2, '0')}-${item.label}"
                            : "${vm.selectedYear}-${item.label}";
                        final value = "${item.value.toStringAsFixed(1)} EGP";
                        return SalesRow(
                          date: date,
                          value: value,
                          onTap: () => _handleRowTap(context, vm, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Pickers
  Future<void> _showMonthYearPicker(
    BuildContext context,
    SalesStatsViewModel vm,
  ) async {
    int tempYear = vm.selectedYear;
    int tempMonth = vm.selectedMonth;
    const int yearStart = 2020;
    final int yearsCount = (DateTime.now().year - yearStart + 1).clamp(1, 50);
    final int initialYearItem = (tempYear - yearStart).clamp(0, yearsCount - 1);

    await showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (modalContext) => Container(
        height: 260,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: (tempMonth - 1).clamp(0, 11),
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => tempMonth = i + 1,
                      children: const [
                        Text("يناير"),
                        Text("فبراير"),
                        Text("مارس"),
                        Text("إبريل"),
                        Text("مايو"),
                        Text("يونيو"),
                        Text("يوليو"),
                        Text("أغسطس"),
                        Text("سبتمبر"),
                        Text("أكتوبر"),
                        Text("نوفمبر"),
                        Text("ديسمبر"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: initialYearItem,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => tempYear = yearStart + i,
                      children: List.generate(
                        yearsCount,
                        (i) => Center(child: Text('${yearStart + i}')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              child: const Text("تم", style: TextStyle(color: Colors.black)),
              onPressed: () {
                vm.updateDate(year: tempYear, month: tempMonth);
                Navigator.of(modalContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showYearPicker(
    BuildContext context,
    SalesStatsViewModel vm,
  ) async {
    int tempYear = vm.selectedYear;
    const int yearStart = 2020;
    final int yearsCount = (DateTime.now().year - yearStart + 1).clamp(1, 50);
    final int initialYearItem = (tempYear - yearStart).clamp(0, yearsCount - 1);

    await showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (modalContext) => Container(
        height: 260,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: initialYearItem,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (i) => tempYear = yearStart + i,
                children: List.generate(
                  yearsCount,
                  (i) => Center(child: Text('${yearStart + i}')),
                ),
              ),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                vm.updateDate(year: tempYear);
                Navigator.of(modalContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleChartTap(
    BuildContext context,
    SalesStatsViewModel vm,
    int index,
  ) {
    final marketId = vm.marketId;
    if (marketId == null || marketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد متجر مرتبط بالحساب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // حساب التاريخ بناءً على نوع العرض (يومي أو شهري)
    DateTime startDate;
    DateTime endDate;

    if (vm.isDaily) {
      // العرض اليومي: label هو رقم اليوم بصيغة "01", "02", إلخ
      // نستخدم نفس البيانات المعروضة في الرسم البياني (أي آخر 15 يوم إذا كان أكثر من 15)
      final chartData = vm.salesData.length > 15
          ? vm.salesData.sublist(vm.salesData.length - 15)
          : vm.salesData;

      if (index < 0 || index >= chartData.length) return;

      final dayLabel = chartData[index].label;
      // label هو رقم اليوم بصيغة "01", "02", إلخ
      final day = int.tryParse(dayLabel) ?? 1;

      startDate = DateTime(vm.selectedYear, vm.selectedMonth, day);
      endDate = startDate.add(const Duration(days: 1));
    } else {
      // العرض الشهري: label هو رقم الشهر بصيغة "01", "02", إلخ
      if (index < 0 || index >= vm.salesData.length) return;

      final monthLabel = vm.salesData[index].label;
      final month = int.tryParse(monthLabel) ?? 1;

      startDate = DateTime(vm.selectedYear, month, 1);
      endDate = DateTime(vm.selectedYear, month + 1, 1);
    }

    // الانتقال إلى صفحة PastOrdersPage
    _navigateToPastOrders(context, marketId, startDate, endDate);
  }

  void _handleRowTap(
    BuildContext context,
    SalesStatsViewModel vm,
    SalesData item,
  ) {
    final marketId = vm.marketId;
    if (marketId == null || marketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد متجر مرتبط بالحساب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // حساب التاريخ بناءً على نوع العرض (يومي أو شهري)
    DateTime startDate;
    DateTime endDate;

    if (vm.isDaily) {
      // العرض اليومي: label هو رقم اليوم بصيغة "01", "02", إلخ
      final dayLabel = item.label;
      final day = int.tryParse(dayLabel) ?? 1;

      startDate = DateTime(vm.selectedYear, vm.selectedMonth, day);
      endDate = startDate.add(const Duration(days: 1));
    } else {
      // العرض الشهري: label هو رقم الشهر بصيغة "01", "02", إلخ
      final monthLabel = item.label;
      final month = int.tryParse(monthLabel) ?? 1;

      startDate = DateTime(vm.selectedYear, month, 1);
      endDate = DateTime(vm.selectedYear, month + 1, 1);
    }

    // الانتقال إلى صفحة PastOrdersPage
    _navigateToPastOrders(context, marketId, startDate, endDate);
  }

  void _navigateToPastOrders(
    BuildContext context,
    String marketId,
    DateTime startDate,
    DateTime endDate,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PastOrdersPage(
          marketId: marketId,
          filterStartDate: startDate,
          filterEndDate: endDate,
        ),
      ),
    );
  }
}
