import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/status_badge.dart';
import '../../../core/constants.dart';

class CustomerInquiriesScreen extends StatelessWidget {
  const CustomerInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const SafeArea(bottom: false, child: TopBar(title: 'Riwayat Inquiry')),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: AppData.inquiries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final inq = AppData.inquiries[i];
                return Container(
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(inq.prop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3)),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: inq.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(LucideIcons.user, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('Sales: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          Text(inq.sales, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('Dikirim: ${inq.date}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('Update: ${inq.lastUpdate}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
