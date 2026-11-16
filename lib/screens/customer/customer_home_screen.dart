import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../widgets/prop_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../core/utils.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();
    
    final categories = [
      {'id': 'house', 'label': 'Rumah', 'emoji': '🏠'},
      {'id': 'apartment', 'label': 'Apartemen', 'emoji': '🏢'},
      {'id': 'villa', 'label': 'Villa', 'emoji': '🏡'},
      {'id': 'shophouse', 'label': 'Ruko', 'emoji': '🏪'},
      {'id': 'office', 'label': 'Kantor', 'emoji': '🏬'},
      {'id': 'land', 'label': 'Tanah', 'emoji': '🌿'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // blue-600 to blue-700
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat pagi,', style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12)),
                          const Text('Rina Lestari 👋', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.bell, color: Colors.white, size: 20),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => appCtrl.customerTab.value = 'search',
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('Cari properti, kota, atau area...', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kategori Properti', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, i) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(categories[i]['emoji']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(categories[i]['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Properti Unggulan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Lihat semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Column(
                      children: appCtrl.featuredProps.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PropCard(
                          p: p,
                          onPress: () => Get.toNamed('/customer_detail', arguments: p.id),
                          onFav: () => appCtrl.toggleFav(p.id),
                          isFav: appCtrl.isFav(p.id),
                        ),
                      )).toList(),
                    )),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Properti Terbaru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Lihat semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: appCtrl.latestProps.length,
                      itemBuilder: (context, i) {
                        final p = appCtrl.latestProps[i];
                        return GestureDetector(
                          onTap: () => Get.toNamed('/customer_detail', arguments: p.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Image.network(p.img, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color: Colors.grey.shade200)),
                                      Positioned(top: 8, left: 8, child: StatusBadge(status: p.status)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(fmtIDR(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
