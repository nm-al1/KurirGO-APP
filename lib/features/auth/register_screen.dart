import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../shared/delivery_scope.dart';
import '../shared/presentation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final username = TextEditingController();
  final phone = TextEditingController();
  final pin = TextEditingController();
  final confirm = TextEditingController();
  bool agreed = false;
  String selectedHub = 'Cabang Pettarani';
  bool hidePin = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    for (final c in [name, username, phone, pin, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = DeliveryScope.of(context);
    final isAvailable = username.text.isNotEmpty &&
        controller.account.isAvailable(username.text);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button Circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF18181B), size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Brand Badge
                  const BrandBadge(),
                ],
              ),
              const SizedBox(height: 16),

              // Page Title & Subtitle
              const Text(
                'Pendaftaran Akun Kurir',
                style: TextStyle(
                  color: Color(0xFF18181B),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Armada Resmi KurirGO • Browcyl Makassar',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 18),

              // Field 1: Nama Lengkap Kurir
              const Text(
                'Nama Lengkap Kurir',
                style: TextStyle(color: Color(0xFF18181B), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: name,
                style: const TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.w600, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Contoh: Ardiansyah Pratama',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.electricLime, width: 2),
                  ),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Isi nama lengkap.' : null,
              ),
              const SizedBox(height: 14),

              // Field 2: Username Akun
              const Text(
                'Username Akun (Untuk Login)',
                style: TextStyle(color: Color(0xFF18181B), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: username,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.w700, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Contoh: ardiansyah',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF10B981), size: 18),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Terpakai',
                      style: TextStyle(
                        color: isAvailable ? const Color(0xFF047857) : const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.electricLime, width: 2),
                  ),
                ),
                validator: (v) => !RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(v ?? '')
                    ? 'Minimal 3 huruf/angka.'
                    : (!controller.account.isAvailable(v!) && v != 'ardiansyah')
                        ? 'Username sudah dipakai.'
                        : null,
              ),
              const SizedBox(height: 14),

              // Fields 3 & 4: PIN Akses & Konfirmasi PIN (2 Kolom Sejajar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PIN Akses (4-6)',
                          style: TextStyle(color: Color(0xFF18181B), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: pin,
                          obscureText: hidePin,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
                          decoration: InputDecoration(
                            labelText: 'Buat PIN',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                          ),
                          validator: (v) => RegExp(r'^\d{4,6}$').hasMatch(v ?? '') ? null : '4-6 digit.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konfirmasi PIN',
                          style: TextStyle(color: Color(0xFF18181B), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirm,
                          obscureText: hideConfirm,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi PIN',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            ),
                          ),
                          validator: (v) => v != pin.text ? 'PIN beda.' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Field 5: Pangkalan Pengantaran Tunggal (Cabang Pettarani)
              const Text(
                'Pangkalan Pengantaran (Pusat Tunggal)',
                style: TextStyle(color: Color(0xFF18181B), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.electricLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cabang Pettarani (Pusat Pengantaran)',
                        style: TextStyle(
                          color: Color(0xFF18181B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Field 6: WhatsApp
              const Text(
                'Nomor WhatsApp / HP (Opsional)',
                style: TextStyle(color: Color(0xFF18181B), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFF18181B), fontWeight: FontWeight.w600, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'WhatsApp (Opsional)',
                  hintText: 'Contoh: 0812-4567-8901',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // SOP Checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: agreed,
                onChanged: (v) => setState(() => agreed = v ?? false),
                activeColor: AppColors.matteCharcoal,
                title: const Text(
                  'Saya menyetujui SOP Higienitas & Pengantaran (LIFO)',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Primary CTA
              ActionPill(
                'Daftar Akun KurirGO',
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  if (!agreed) {
                    showProblem(context, 'Setujui SOP pengantaran.');
                    return;
                  }
                  try {
                    controller.account.register(
                      name: name.text,
                      username: username.text,
                      pin: pin.text,
                      whatsapp: phone.text.isEmpty ? null : phone.text,
                    );
                    controller.login(username.text, pin.text);
                    replaceWith(context, '/dashboard');
                  } catch (e) {
                    showProblem(context, e);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Switch to Login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Sudah punya akun kurir? ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Masuk di sini',
                          style: TextStyle(
                            color: Color(0xFF18181B),
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}
