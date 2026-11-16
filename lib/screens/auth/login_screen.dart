import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppController appCtrl = Get.find<AppController>();
  
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPw = false;
  String _error = "";
  bool _loading = false;

  void _handleSubmit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = "Email dan password wajib diisi.");
      return;
    }
    setState(() {
      _loading = true;
      _error = "";
    });
    await Future.delayed(const Duration(milliseconds: 700));
    final ok = appCtrl.login(_emailCtrl.text, _passCtrl.text);
    if (!ok) {
      setState(() {
        _error = "Email atau password tidak ditemukan. Periksa kembali.";
        _loading = false;
      });
    }
  }

  void _fillDemo(String type) {
    if (type == "customer") {
      _emailCtrl.text = "customer@propertyapp.test";
      _passCtrl.text = "Customer123!";
    } else {
      _emailCtrl.text = "sales@propertyapp.test";
      _passCtrl.text = "Sales123!";
    }
    setState(() => _error = "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.building, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Selamat Datang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Masuk ke akun Anda untuk melanjutkan', style: TextStyle(fontSize: 14, color: Color(0xFFBFDBFE))),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 1)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email Anda',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 1)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passCtrl,
                      obscureText: !_showPw,
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password Anda',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                        suffixIcon: IconButton(
                          icon: Icon(_showPw ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey.shade400),
                          onPressed: () => setState(() => _showPw = !_showPw),
                        ),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Lupa password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade600)),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _loading ? null : _handleSubmit,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _loading ? Colors.blue.shade300 : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text(_loading ? 'Memproses...' : 'Masuk', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum punya akun? ',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          children: [
                            TextSpan(text: 'Daftar sekarang', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DEMO AKUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155), letterSpacing: 1)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _fillDemo('customer'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                              child: Row(
                                children: [
                                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle), child: const Icon(LucideIcons.user, color: Colors.white, size: 16)),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                    Text('customer@propertyapp.test', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB))),
                                  ])),
                                  Text('Gunakan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.blue.shade500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _fillDemo('sales'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle), child: const Icon(LucideIcons.barChart2, color: Colors.white, size: 16)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('Sales', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    Text('sales@propertyapp.test', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                  ])),
                                  Text('Gunakan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
