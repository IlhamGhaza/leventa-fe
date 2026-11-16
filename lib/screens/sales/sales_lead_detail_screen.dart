import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/status_badge.dart';

class SalesLeadDetailScreen extends StatelessWidget {
  const SalesLeadDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leadId = Get.arguments as String;
    final l = AppData.leads.firstWhere((x) => x.id == leadId);

    final icons = {
      'inquiry': LucideIcons.messageSquare,
      'assign': LucideIcons.users,
      'call': LucideIcons.phone,
      'schedule': LucideIcons.calendar,
      'complete': LucideIcons.checkCircle,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const SafeArea(bottom: false, child: TopBar(title: 'Detail Lead')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            UserAvatar(name: l.customer, size: 'lg'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.customer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text(l.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  Text(l.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: l.status),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade100)),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.phone, size: 14, color: Colors.green.shade600),
                                      const SizedBox(width: 6),
                                      Text('Telepon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF25D366).withOpacity(0.2))),
                                  child: const Row(
                                    children: [
                                      Icon(LucideIcons.messageSquare, size: 14, color: Color(0xFF128C7E)),
                                      SizedBox(width: 6),
                                      Text('WA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF128C7E))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                        const Text('Info Lead', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        _buildInfoRow('Properti', l.prop),
                        const SizedBox(height: 10),
                        _buildInfoRow('Anggaran', fmtIDR(l.budget), isHighlight: true),
                        const SizedBox(height: 10),
                        _buildInfoRow('Masuk sejak', l.date),
                        const SizedBox(height: 10),
                        _buildInfoRow('Follow-up berikutnya', l.nextFU, isWarn: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                        const Text('Timeline Aktivitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            Positioned(
                              left: 15.5, top: 0, bottom: 0,
                              child: Container(width: 1, color: Colors.grey.shade200),
                            ),
                            Column(
                              children: AppData.timeline.map((t) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200, width: 2)),
                                        child: Icon(icons[t.type], size: 14, color: t.type == 'complete' ? Colors.green.shade600 : Colors.blue.shade600),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.event, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                            const SizedBox(height: 2),
                                            Text(t.detail, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
                                            const SizedBox(height: 4),
                                            Text(t.date, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 8)],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.calendar, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Jadwal Survey', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plus, size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text('Add Follow-Up', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.25), blurRadius: 8)],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.check, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Mark Won', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.x, size: 14, color: Colors.red.shade600),
                              const SizedBox(width: 6),
                              Text('Mark Lost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, {bool isHighlight = false, bool isWarn = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFF2563EB) : isWarn ? Colors.amber.shade700 : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
