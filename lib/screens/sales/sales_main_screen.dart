import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/responsive_layout.dart';
import 'sales_dashboard_screen.dart';
import 'sales_leads_screen.dart';
import 'sales_properties_screen.dart';
import 'sales_schedule_screen.dart';
import 'sales_profile_screen.dart';

class SalesMainScreen extends StatelessWidget {
  const SalesMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();

    final screens = {
      'dashboard': const SalesDashboardScreen(),
      'leads': const SalesLeadsScreen(),
      'properties': const SalesPropertiesScreen(),
      'schedule': const SalesScheduleScreen(),
      'profile': const SalesProfileScreen(),
    };

    final items = [
      {'id': 'dashboard', 'icon': LucideIcons.barChart2, 'label': 'Dashboard'},
      {'id': 'leads', 'icon': LucideIcons.users, 'label': 'Leads'},
      {'id': 'properties', 'icon': LucideIcons.building, 'label': 'Properti'},
      {'id': 'schedule', 'icon': LucideIcons.calendar, 'label': 'Jadwal'},
      {'id': 'profile', 'icon': LucideIcons.user, 'label': 'Profil'},
    ];

    Widget buildBottomNav() {
      return Obx(() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: items.map((item) {
            final id = item['id'] as String;
            final isActive = appCtrl.salesTab.value == id;
            return Expanded(
              child: GestureDetector(
                onTap: () => appCtrl.salesTab.value = id,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData, size: 20, color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade400),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ));
    }

    return ResponsiveLayout(
      mobile: Scaffold(
        body: Obx(() => screens[appCtrl.salesTab.value] ?? const SizedBox.shrink()),
        bottomNavigationBar: buildBottomNav(),
      ),
    );
  }
}
