import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants.dart';
import '../../../widgets/lead_card.dart';

class SalesLeadsScreen extends StatefulWidget {
  const SalesLeadsScreen({super.key});

  @override
  State<SalesLeadsScreen> createState() => _SalesLeadsScreenState();
}

class _SalesLeadsScreenState extends State<SalesLeadsScreen> {
  final _tabs = ["all", "new", "contacted", "qualified", "survey", "negotiation", "won", "lost"];
  final _labels = {
    "all": "Semua", "new": "Baru", "contacted": "Hubungi", "qualified": "Qualified",
    "survey": "Survey", "negotiation": "Nego", "won": "Won", "lost": "Gagal",
  };
  String _active = "all";

  @override
  Widget build(BuildContext context) {
    final filtered = _active == "all" ? AppData.leads : AppData.leads.where((l) => l.status == _active).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lead Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.map((t) {
                      final isActive = _active == t;
                      return GestureDetector(
                        onTap: () => setState(() => _active = t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6, bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _labels[t]!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 40, color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        Text('Tidak ada lead', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final l = filtered[i];
                      return LeadCard(
                        l: l,
                        onPress: () => Get.toNamed('/sales_lead_detail', arguments: l.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
