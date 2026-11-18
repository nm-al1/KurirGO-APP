import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../shared/delivery_scope.dart';
import '../shared/presentation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(text: 'ardiansyah');
  final pin = TextEditingController(text: '1234');
  bool rememberMe = true;
  bool hidePin = true;

  @override
  void dispose() {
    username.dispose();
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = DeliveryScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.matteCharcoal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Brand Header Area (Matte Charcoal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Official KurirGO Emblem Badge (64x64)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202024),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF2E2E33),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricLime.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/brand/kurirgo_icon.png',
                        width: 64,
                        height: 64,
                        semanticLabel: 'Logo KurirGO',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // App Title: Official KurirGO Typographic Wordmark
                  RichText(
                    text: const TextSpan(
                      text: 'Kurir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'GO',
                          style: TextStyle(
                            color: AppColors.electricLime,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  const Text(
                    'BROWCYL DELIVERY • MAKASSAR',
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Hub Location Pill Badge
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.electricLime,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Hub Pettarani (Base Depot)',
                            style: TextStyle(
                              color: Color(0xFFE4E4E7),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Login Form Container (Curved White Sheet)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Form(
                  key: form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    children: [
                      // Drag Handle Notch
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Title
                      const Text(
                        'Masuk Akun Kurir',
                        style: TextStyle(
                          color: Color(0xFF18181B),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gunakan username yang telah Anda daftarkan di sistem',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Input Field 1: Username / No. HP
                      const Text(
                        'Username atau No. Handphone',
                        style: TextStyle(
                          color: Color(0xFF18181B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: username,
                        style: const TextStyle(
                          color: Color(0xFF18181B),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: ardiansyah',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.electricLime,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Isi username.' : null,
                      ),
                      const SizedBox(height: 14),

                      // Input Field 2: PIN Akses
                      const Text(
                        'PIN Akses (4-6 Digit)',
                        style: TextStyle(
                          color: Color(0xFF18181B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: pin,
                        obscureText: hidePin,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Color(0xFF18181B),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 3,
                        ),
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          labelStyle: const TextStyle(color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePin
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => setState(() => hidePin = !hidePin),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.electricLime,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{4,6}$').hasMatch(value ?? '')
                            ? null
                            : 'PIN harus 4–6 digit.',
                      ),
                      const SizedBox(height: 4),

                      // Lupa PIN Action
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Akses Demo'),
                              content: const Text(
                                'Gunakan ardiansyah / 1234 atau daftar akun baru.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Mengerti'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text(
                            'Lupa PIN?',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Notice Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF64748B),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Khusus Mitra Browcyl: Pastikan GPS aktif saat bertugas.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary Action CTA: Masuk ke Sistem Pengantaran
                      ActionPill(
                        'Masuk ke Sistem Pengantaran',
                        onPressed: () {
                          if (!form.currentState!.validate()) return;
                          try {
                            controller.login(username.text, pin.text);
                            replaceWith(context, '/dashboard');
                          } catch (e) {
                            showProblem(context, e);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Switch to Register (Standalone Text for WidgetTester finder)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Daftar Akun KurirGO',
                            style: TextStyle(
                              color: Color(0xFF18181B),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
