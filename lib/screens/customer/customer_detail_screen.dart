import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/user_avatar.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();
    final String propId = Get.arguments as String;
    final p = AppData.props.firstWhere((x) => x.id == propId);

    void showInquirySheet() {
      Get.bottomSheet(
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kirim Inquiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(LucideIcons.x, size: 16, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROPERTI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900), maxLines: 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nama Lengkap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(text: 'Rina Lestari'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nomor Telepon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(text: '+62 812 3456 7890'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Pesan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Sampaikan pertanyaan atau kebutuhan Anda...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          'Inquiry Terkirim!',
                          'Tim Sales kami akan segera menghubungi Anda.',
                          backgroundColor: Colors.green.shade50,
                          colorText: Colors.green.shade900,
                          icon: Icon(LucideIcons.checkCircle, color: Colors.green.shade600),
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Kirim Inquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(p.img, height: 260, width: double.infinity, fit: BoxFit.cover),
                      Positioned(
                        top: 40,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                child: Icon(LucideIcons.arrowLeft, size: 16, color: Colors.grey.shade800),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                  child: Icon(LucideIcons.share2, size: 16, color: Colors.grey.shade800),
                                ),
                                const SizedBox(width: 8),
                                Obx(() {
                                  final isFav = appCtrl.isFav(propId);
                                  return GestureDetector(
                                    onTap: () => appCtrl.toggleFav(propId),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                      child: Icon(LucideIcons.heart, size: 16, color: isFav ? Colors.red : Colors.grey.shade800),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: const Text('1 / 5', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: p.status),
                            Text(p.type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Expanded(child: Text(p.loc, style: TextStyle(fontSize: 14, color: Colors.grey.shade500))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            text: fmtIDR(p.price),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF2563EB)),
                            children: [
                              if (p.unit.isNotEmpty) TextSpan(text: ' ${p.unit}', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                        if (p.beds > 0 || p.baths > 0 || p.build > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                if (p.beds > 0) Expanded(child: _buildFacIcon(LucideIcons.bed, '${p.beds}', 'Kamar')),
                                if (p.baths > 0) Expanded(child: _buildFacIcon(LucideIcons.bath, '${p.baths}', 'KM')),
                                if (p.build > 0) Expanded(child: _buildFacIcon(LucideIcons.building, '${p.build}', 'm² LB')),
                                if (p.land > 0) Expanded(child: _buildFacIcon(LucideIcons.target, '${p.land}', 'm² LT')),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        Text(p.desc, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
                        const SizedBox(height: 20),
                        const Text('Fasilitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ["Carport", "Taman", "Air PDAM", "Listrik PLN", "Keamanan 24 Jam", "Akses Tol"].map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                              child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Agen Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const UserAvatar(name: 'Andi Pratama', size: 'md', bg: Color(0xFF059669)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Andi Pratama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                        Text('+62 811 2345 6789', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                        child: Icon(LucideIcons.phone, size: 16, color: Colors.green.shade600),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                        child: Icon(LucideIcons.messageSquare, size: 16, color: Colors.blue.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2563EB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.phone, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text('Hubungi Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: showInquirySheet,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Kirim Inquiry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacIcon(IconData icon, String val, String label) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 16, color: Colors.blue.shade600),
        ),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }
}
