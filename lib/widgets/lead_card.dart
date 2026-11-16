import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/utils.dart';
import 'status_badge.dart';
import 'user_avatar.dart';

class LeadCard extends StatelessWidget {
  final LeadItem l;
  final VoidCallback onPress;

  const LeadCard({super.key, required this.l, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: l.customer, size: 'md'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.customer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        l.prop,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: l.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.shade50),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfo('Anggaran', fmtIDR(l.budget), Colors.grey.shade800),
                _buildInfo('Kontak terakhir', l.lastContact, Colors.grey.shade700),
                _buildInfo('Follow-up', l.nextFU, const Color(0xFF2563EB)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valColor,
          ),
        ),
      ],
    );
  }
}
