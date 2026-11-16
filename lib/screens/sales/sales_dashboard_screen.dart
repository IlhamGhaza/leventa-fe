import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants.dart';
import '../../../widgets/kpi_card.dart';
import '../../../widgets/lead_card.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat pagi,', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Text('Andi Pratama 👋', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Agustus 2026 · Target: 10 Deal', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.bell, color: Color(0xFFCBD5E1), size: 20),
                      ),
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(child: KpiCard(label: 'Lead Baru', value: '5', sub: 'Perlu follow-up', color: Color(0xFF2563EB), icon: LucideIcons.users)),
                        SizedBox(width: 12),
                        Expanded(child: KpiCard(label: 'Follow-Up', value: '3', sub: 'Hari ini', color: Color(0xFFF59E0B), icon: LucideIcons.clock)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: KpiCard(label: 'Survey', value: '2', sub: '14:00 & 16:30', color: Color(0xFF8B5CF6), icon: LucideIcons.calendar)),
                        SizedBox(width: 12),
                        Expanded(child: KpiCard(label: 'Deal Bulan Ini', value: '8', sub: '80% dari target', color: Color(0xFF22C55E), icon: LucideIcons.award)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deal per Bulan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 110,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 10,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, meta) => Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(AppData.chartData[v.toInt()].m, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                      reservedSize: 24,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 2,
                                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1, dashArray: [3, 3]),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: AppData.chartData.asMap().entries.map((e) {
                                  return BarChartGroupData(
                                    x: e.key,
                                    barRods: [BarChartRodData(toY: e.value.v.toDouble(), color: const Color(0xFF2563EB), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pipeline Lead', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('Total 35', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...AppData.pipeline.map((p) {
                            final color = Color(int.parse(p.color, radix: 16));
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(width: 72, child: Text(p.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)))),
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: p.count / 10,
                                        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 24, child: Text('${p.count}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lead Terbaru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        GestureDetector(
                          onTap: () => appCtrl.salesTab.value = 'leads',
                          child: const Text('Lihat semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...AppData.leads.take(3).map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LeadCard(
                        l: l,
                        onPress: () => Get.toNamed('/sales_lead_detail', arguments: l.id),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
