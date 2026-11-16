import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('2 belum dibaca', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Text('Tandai dibaca', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: AppData.notifs.length,
              separatorBuilder: (_, __) => Container(height: 1, color: Colors.grey.shade50),
              itemBuilder: (context, i) {
                final n = AppData.notifs[i];
                return Container(
                  color: !n.read ? Colors.blue.shade50.withOpacity(0.6) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: !n.read ? Colors.blue.shade100 : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(LucideIcons.bell, size: 16, color: !n.read ? Colors.blue.shade600 : Colors.grey.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(n.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: !n.read ? const Color(0xFF0F172A) : Colors.grey.shade700)),
                                if (!n.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
                            const SizedBox(height: 4),
                            Text(n.time, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ),
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
