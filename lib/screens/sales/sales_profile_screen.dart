import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/kpi_card.dart';

class SalesProfileScreen extends StatelessWidget {
  const SalesProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();
    
    final menus = [
      {'label': 'Edit Profil', 'icon': LucideIcons.user},
      {'label': 'Performa Saya', 'icon': LucideIcons.barChart2},
      {'label': 'Notifikasi', 'icon': LucideIcons.bell},
      {'label': 'Ubah Password', 'icon': LucideIcons.fileText},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profil Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const UserAvatar(name: 'Andi Pratama', size: 'lg', bg: Color(0xFF059669)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Andi Pratama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('ID: EMP-20241 · Senior Sales', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          const Text('sales@propertyapp.test', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
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
                        Expanded(child: KpiCard(label: 'Total Lead', value: '35', sub: 'Bulan ini', color: Color(0xFF2563EB), icon: LucideIcons.users)),
                        SizedBox(width: 12),
                        Expanded(child: KpiCard(label: 'Deal Menang', value: '8 / 10', sub: '80% tercapai', color: Color(0xFF22C55E), icon: LucideIcons.award)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(child: KpiCard(label: 'Konversi', value: '22.8%', sub: 'Rate bulan ini', color: Color(0xFF8B5CF6), icon: LucideIcons.trendingUp)),
                        SizedBox(width: 12),
                        Expanded(child: KpiCard(label: 'Komisi', value: 'Rp 48 Jt', sub: 'Estimasi', color: Color(0xFFF59E0B), icon: LucideIcons.target)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...menus.map((m) {
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(m['icon'] as IconData, size: 16, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(m['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                ],
                              ),
                              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => appCtrl.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Icon(LucideIcons.logOut, size: 16, color: Colors.red.shade500),
                            ),
                            const SizedBox(width: 12),
                            const Text('Keluar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
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
