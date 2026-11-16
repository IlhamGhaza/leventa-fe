import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants.dart';
import '../../../widgets/prop_card.dart';

class SalesPropertiesScreen extends StatelessWidget {
  const SalesPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Properti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('5 tersedia · 1 terjual', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(LucideIcons.filter, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: AppData.props.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = AppData.props[i];
                return Obx(() => PropCard(
                  p: p,
                  onPress: () => Get.toNamed('/customer_detail', arguments: p.id), // using customer detail for preview
                  onFav: () => appCtrl.toggleFav(p.id),
                  isFav: appCtrl.isFav(p.id),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
