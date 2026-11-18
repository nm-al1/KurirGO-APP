import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import '../shared/presentation.dart' show BrandBadge;

class AuthPage extends StatefulWidget {
  final SupabaseClient backend;
  final bool recovery;
  final VoidCallback? onRecovered;
  const AuthPage({
    required this.backend,
    this.recovery = false,
    this.onRecovered,
    super.key,
  });
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(6, (_) => TextEditingController());
  bool register = false, reset = false, busy = false, visible = false;
  String? message;
  String? get redirect => kIsWeb ? Uri.base.origin : authRedirect;
  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = widget.backend.auth;
      if (widget.recovery) {
        await auth.updateUser(UserAttributes(password: fields[3].text));
        widget.onRecovered?.call();
      } else if (reset) {
        await auth.resetPasswordForEmail(
          fields[2].text.trim(),
          redirectTo: redirect,
        );
        message = 'Jika email terdaftar, tautan pemulihan akan dikirim. Periksa juga folder spam.';
      } else if (register) {
        await auth.signUp(
          email: fields[2].text.trim(),
          password: fields[3].text,
          emailRedirectTo: redirect,
          data: {
            'full_name': fields[0].text.trim(),
            'username': fields[1].text.trim().toLowerCase(),
            'phone': fields[4].text.trim(),
          },
        );
        message = 'Pendaftaran diterima. Verifikasi email sebelum masuk.';
        register = false;
      } else {
        final result = await widget.backend.functions.invoke(
          'username-login',
          body: {
            'username': fields[1].text.trim().toLowerCase(),
            'password': fields[3].text,
          },
        );
        final token = result.data is Map ? result.data['refresh_token'] : null;
        if (token is! String) {
          throw StateError(
            'Username atau password tidak cocok, atau email belum diverifikasi.',
          );
        }
        await auth.setSession(token);
      }
    } catch (error) {
      if (mounted) problem(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(
    int i,
    String label,
    String hint, {
    bool password = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: fields[i],
      obscureText: password && !visible,
      keyboardType: keyboard,
      autocorrect: !password && i == 0,
      enableSuggestions: !password,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: password
            ? IconButton(
                tooltip: visible
                    ? 'Sembunyikan password'
                    : 'Tampilkan password',
                onPressed: () => setState(() => visible = !visible),
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
      validator: (raw) {
        final value = raw ?? '';
        if (value.trim().isEmpty) return '$label wajib diisi';
        if (i == 1 && !RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(value.trim())) {
          return 'Gunakan 3–24 huruf, angka, atau underscore';
        }
        if (i == 2 &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
          return 'Email belum valid';
        }
        if (i == 3 && value.length < 8) return 'Minimal 8 karakter';
        if (i == 4 && !RegExp(r'^0[0-9]{8,14}$').hasMatch(value.trim())) {
          return 'Gunakan 9–15 digit, diawali 0';
        }
        if (i == 5 && value != fields[3].text) {
          return 'Konfirmasi password tidak sama';
        }
        return null;
      },
      onFieldSubmitted: (_) => submit(),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: register || reset || widget.recovery
        ? const Color(0xFFF8FAFC)
        : ink,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: form,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (!register && !reset && !widget.recovery)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/brand/kurirgo_icon.png',
                          height: 64,
                          width: 64,
                          semanticLabel: 'Logo KurirGO',
                        ),
                        const SizedBox(height: 12),
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Kurir',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'GO',
                                style: TextStyle(color: lime),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'BROWCYL DELIVERY · MAKASSAR',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '●  Hub Pettarani Base Depot',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (register || reset || widget.recovery) ...[
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Kembali ke masuk',
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                      register = false;
                                      reset = false;
                                      message = null;
                                    }),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            const BrandBadge(),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        widget.recovery
                            ? 'Password baru'
                            : reset
                            ? 'Pulihkan akun'
                            : register
                            ? 'Pendaftaran Akun Kurir'
                            : 'Masuk Akun Kurir',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.recovery
                            ? 'Gunakan minimal 8 karakter.'
                            : reset
                            ? 'Tautan pemulihan dikirim ke email akun.'
                            : 'Browcyl Delivery · Makassar',
                      ),
                      const SizedBox(height: 24),
                      if (register && !reset && !widget.recovery)
                        input(
                          0,
                          'Nama kurir',
                          'Masukkan Nama',
                          keyboard: TextInputType.name,
                        ),
                      if (!reset && !widget.recovery)
                        input(1, 'Username', 'Username'),
                      if ((register || reset) && !widget.recovery)
                        input(
                          2,
                          'Email',
                          'Email',
                          keyboard: TextInputType.emailAddress,
                        ),
                      if (!reset)
                        input(
                          3,
                          widget.recovery ? 'Password baru' : 'Password',
                          widget.recovery
                              ? 'Minimal 8 karakter'
                              : 'Masukkan password',
                          password: true,
                        ),
                      if (register && !reset && !widget.recovery)
                        input(
                          4,
                          'WhatsApp',
                          '081xxxx',
                          keyboard: TextInputType.phone,
                        ),
                      if ((register || widget.recovery) && !reset)
                        input(
                          5,
                          'Konfirmasi password',
                          'Ulangi password',
                          password: true,
                        ),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(message!, semanticsLabel: message),
                        ),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Text(
                          busy
                              ? 'Memproses…'
                              : widget.recovery
                              ? 'Simpan password'
                              : reset
                              ? 'Kirim tautan pemulihan'
                              : register
                              ? 'Daftar'
                              : 'Masuk',
                        ),
                      ),
                      if (!widget.recovery) ...[
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  register = !register;
                                  reset = false;
                                  message = null;
                                  form.currentState?.reset();
                                }),
                          child: Text(
                            register
                                ? 'Sudah punya akun? Masuk'
                                : 'Belum punya akun? Daftar',
                          ),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  reset = !reset;
                                  message = null;
                                  form.currentState?.reset();
                                }),
                          child: Text(
                            reset ? 'Kembali ke masuk' : 'Lupa password?',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
