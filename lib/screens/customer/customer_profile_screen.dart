import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../widgets/user_avatar.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();
    
    final menus = [
      {'label': 'Edit Profil', 'icon': LucideIcons.user, 'action': () {}},
      {'label': 'Inquiry Saya', 'icon': LucideIcons.fileText, 'action': () => Get.toNamed('/customer_inquiries')},
      {'label': 'Favorit', 'icon': LucideIcons.heart, 'action': () => appCtrl.customerTab.value = 'favorites'},
      {'label': 'Notifikasi', 'icon': LucideIcons.bell, 'action': () => appCtrl.customerTab.value = 'notifications'},
      {'label': 'Ubah Password', 'icon': LucideIcons.award, 'action': () {}},
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
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profil Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const UserAvatar(name: 'Rina Lestari', size: 'lg', bg: Color(0xFF1D4ED8)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rina Lestari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text('customer@propertyapp.test', style: TextStyle(fontSize: 12, color: Color(0xFFBFDBFE))),
                          const SizedBox(height: 2),
                          const Text('+62 812 3456 7890', style: TextStyle(fontSize: 12, color: Color(0xFFBFDBFE))),
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
                    ...menus.map((m) {
                      return GestureDetector(
                        onTap: m['action'] as VoidCallback,
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
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(m['icon'] as IconData, size: 16, color: Colors.blue.shade600),
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
                    const SizedBox(height: 12),
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
