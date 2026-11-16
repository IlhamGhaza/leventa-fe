import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../core/utils.dart';
import 'status_badge.dart';

class PropCard extends StatelessWidget {
  final PropItem p;
  final VoidCallback onPress;
  final VoidCallback onFav;
  final bool isFav;

  const PropCard({
    super.key,
    required this.p,
    required this.onPress,
    required this.onFav,
    required this.isFav,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Image.network(
                  p.img,
                  height: 176, // 44 * 4
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 176, color: Colors.grey.shade200),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusBadge(status: p.status),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFav,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        size: 16,
                        color: isFav ? Colors.red : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.loc,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: fmtIDR(p.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2563EB),
                      ),
                      children: [
                        if (p.unit.isNotEmpty)
                          TextSpan(
                            text: ' ${p.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (p.beds > 0 || p.baths > 0 || p.build > 0) ...[
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.grey.shade50),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (p.beds > 0) ...[
                          Icon(LucideIcons.bed, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${p.beds}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(width: 12),
                        ],
                        if (p.baths > 0) ...[
                          Icon(LucideIcons.bath, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${p.baths}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(width: 12),
                        ],
                        if (p.build > 0) ...[
                          Icon(LucideIcons.building, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${p.build} m²', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
