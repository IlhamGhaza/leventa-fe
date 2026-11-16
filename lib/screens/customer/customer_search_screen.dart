import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../widgets/prop_card.dart';
import '../../../core/constants.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final AppController appCtrl = Get.find<AppController>();
  String _query = '';
  String _activeFilter = 'Semua';
  final List<String> filters = ["Semua", "Rumah", "Apartemen", "Villa", "Ruko", "Gudang"];

  @override
  Widget build(BuildContext context) {
    final results = AppData.props.where((p) {
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.loc.toLowerCase().contains(q);
      final matchFilter = _activeFilter == 'Semua' || p.type == _activeFilter;
      return matchQuery && matchFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _query = val),
                          decoration: InputDecoration(
                            hintText: 'Cari properti, kota, area...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            // Can't clear textfield easily without controller, but state is enough for demo
                            setState(() => _query = '');
                          },
                          child: Icon(LucideIcons.x, size: 16, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final isActive = _activeFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${results.length} properti ditemukan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Row(
                  children: [
                    Icon(LucideIcons.filter, size: 12, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.building, size: 40, color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        Text('Properti tidak ditemukan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = results[i];
                      return Obx(() => PropCard(
                            p: p,
                            onPress: () => Get.toNamed('/customer_detail', arguments: p.id),
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
