import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../shared/delivery_scope.dart';
import '../shared/presentation.dart';

ThemeData _courierTheme(BuildContext context) => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme.light(
    primary: AppColors.matteCharcoal,
    onPrimary: Colors.white,
    secondary: AppColors.electricLime,
    surface: AppColors.backgroundLight,
    onSurface: AppColors.textDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundLight,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  ),
  textTheme: Theme.of(context).textTheme
      .apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark),
);

class CourierTabs extends StatelessWidget {
  final int selected;
  const CourierTabs({required this.selected, super.key});
  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.matteCharcoal,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(6),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (final (i, label, icon, route) in [
            (0, 'Home', Icons.home_outlined, '/dashboard'),
            (1, 'Performa', Icons.bar_chart, '/performance'),
            (2, 'Profil', Icons.person_outline, '/profile'),
          ])
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: selected == i
                    ? AppColors.textDark
                    : Colors.white,
                backgroundColor: selected == i
                    ? AppColors.electricLime
                    : Colors.transparent,
                minimumSize: const Size(48, 48),
              ),
              onPressed: () {
                if (selected != i) replaceWith(context, route);
              },
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
        ],
      ),
    ),
  );
}

class CourierDetailsPage extends StatelessWidget {
  final bool performance;
  const CourierDetailsPage({this.performance = false, super.key});
  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    return Theme(
      data: _courierTheme(context),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(
            performance ? 'Performa Kurir' : 'Profil Mitra Kurir',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 16), child: BrandBadge()),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.matteCharcoal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/brand/kurirgo_icon.png',
                    width: 56,
                    height: 56,
                    semanticLabel: 'Logo KurirGO',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    performance
                        ? '${c.boxesDelivered} Box Selesai'
                        : c.account.fullName,
                    style: const TextStyle(
                      color: AppColors.electricLime,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    performance
                        ? '${c.completedOrders.length} / ${c.orders.length} pesanan pada rute ini'
                        : '@${c.username} • Cabang Pettarani',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (performance) ...[
              const Text(
                'PENGANTARAN RUTE INI',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final order in c.orders)
                ListTile(
                  title: Text(order.id),
                  subtitle: Text('${order.boxCount} Box'),
                  trailing: Icon(
                    c.completedOrders.contains(order)
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    color: AppColors.statusGreen,
                  ),
                ),
              const Divider(),
              ListTile(
                title: const Text('Uang Diterima'),
                trailing: Text(rupiah(c.revenue)),
              ),
              ListTile(
                title: const Text('Tunai / COD Wajib Setor'),
                trailing: Text(rupiah(c.cashToDeposit)),
              ),
              ListTile(
                title: const Text('Non-Tunai'),
                trailing: Text(rupiah(c.nonCashTotal)),
              ),
              const Text(
                'Data sesi demo saat ini. Riwayat mingguan dan rating belum tersedia.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ] else ...[
              const ListTile(
                leading: Icon(Icons.location_on_outlined),
                title: Text('Wilayah Operasional'),
                subtitle: Text('Makassar Timur & Sudiang • Hub Pettarani'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('WhatsApp'),
                subtitle: Text(
                  c.account.phone?.isNotEmpty == true
                      ? c.account.phone!
                      : 'Belum diisi',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Kepatuhan Operasional'),
                subtitle: Text(
                  'Muat LIFO, periksa segel utuh, dan setor tunai di depot.',
                ),
              ),
              const SizedBox(height: 16),
              ActionPill(
                'Ubah Profil',
                icon: Icons.edit_outlined,
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun demo lokal. Perubahan profil tersimpan selama proses aplikasi berjalan.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: CourierTabs(selected: performance ? 1 : 2),
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController();
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      final account = DeliveryScope.of(context).account;
      name.text = account.fullName;
      phone.text = account.phone ?? '';
      initialized = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _courierTheme(context),
    child: Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Ubah Profil Kurir'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: BrandBadge()),
        ],
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Image.asset(
                'assets/brand/kurirgo_icon.png',
                width: 72,
                height: 72,
                semanticLabel: 'Logo KurirGO',
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi nama lengkap.' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (opsional)',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ||
                      RegExp(r'^\+?[0-9 -]{8,20}$').hasMatch(v!.trim())
                  ? null
                  : 'Nomor WhatsApp tidak valid.',
            ),
            const SizedBox(height: 24),
            ActionPill(
              'Simpan Perubahan Profil',
              icon: Icons.check,
              onPressed: () {
                if (!form.currentState!.validate()) return;
                try {
                  DeliveryScope.of(context)
                      .updateProfile(name.text, phone.text);
                  Navigator.pop(context);
                } catch (error) {
                  showProblem(context, error);
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal & Kembali ke Profil'),
            ),
          ],
        ),
      ),
    ),
  );
}
