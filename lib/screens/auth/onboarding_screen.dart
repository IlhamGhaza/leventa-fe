import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  final List<Map<String, String>> steps = [
    {
      'img': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=780&h=440&fit=crop&auto=format',
      'title': 'Temukan Properti Impian Anda',
      'desc': 'Jelajahi ribuan pilihan properti — rumah, apartemen, villa, ruko — di seluruh Indonesia dengan harga terbaik.',
    },
    {
      'img': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=780&h=440&fit=crop&auto=format',
      'title': 'Hubungi Tim Sales Kami',
      'desc': 'Kirim inquiry langsung ke tim sales berpengalaman kami. Kami siap membantu menemukan properti yang tepat untuk Anda.',
    },
    {
      'img': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=780&h=440&fit=crop&auto=format',
      'title': 'Kelola Properti dengan Mudah',
      'desc': 'Platform terintegrasi untuk manajemen properti, owner, tenant, leads, dan laporan bisnis secara lengkap.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _step = i),
                  itemCount: steps.length,
                  itemBuilder: (context, i) {
                    return Image.network(
                      steps[i]['img']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.white, Colors.white.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Get.offNamed('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Lewati', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(steps.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _step == i ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _step == i ? const Color(0xFF2563EB) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    steps[_step]['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      steps[_step]['desc']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
                    ),
                  ),
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text('Kembali', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_step < 2) {
                              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            } else {
                              Get.offNamed('/login');
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _step < 2 ? 'Lanjut →' : 'Mulai Sekarang →',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
