import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../widgets/prop_card.dart';

class CustomerFavoritesScreen extends StatelessWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Favorit Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Obx(() => Text('${appCtrl.favoriteProps.length} properti tersimpan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final favs = appCtrl.favoriteProps;
              if (favs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                        child: Icon(LucideIcons.heart, size: 32, color: Colors.red.shade200),
                      ),
                      const SizedBox(height: 12),
                      const Text('Belum ada favorit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      Text('Tambahkan properti yang Anda sukai\nke daftar favorit', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appCtrl.customerTab.value = 'home',
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Jelajahi Properti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: favs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = favs[i];
                  return PropCard(
                    p: p,
                    onPress: () => Get.toNamed('/customer_detail', arguments: p.id),
                    onFav: () => appCtrl.toggleFav(p.id),
                    isFav: true,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
