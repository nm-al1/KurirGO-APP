import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../../data/profile_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/number_format.dart';
import '../../data/courier_store.dart';
import '../controllers/courier_runtime.dart';
import '../shared/isometric_box.dart';
import '../shared/presentation.dart' show BrandBadge, rupiah;
import 'app.dart';
import 'figcraft_widgets.dart';
import 'order_form.dart';
import 'trip_page.dart';

String dateLabel(String? value) => value == null
    ? 'Belum disetor'
    : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value).toLocal());

class CourierHome extends StatefulWidget {
  final CourierRuntime runtime;
  const CourierHome({required this.runtime, super.key});
  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  CourierRuntime get c => widget.runtime;
  int tab = 0;
  bool busy = false;
  final selected = <String>{};
  final search = TextEditingController();
  DateTimeRange? dates;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => recoverPhoto());
    }
  }

  Future<void> recoverPhoto() async {
    try {
      final recovered = await ImagePicker().retrieveLostData();
      if (recovered.exception != null) throw recovered.exception!;
      if (mounted && (recovered.files?.isNotEmpty ?? false)) {
        await openPage(
          context,
          EditCourierProfile(
            runtime: c,
            recoveredPhoto: recovered.files!.first,
          ),
        );
      }
    } catch (e) {
      if (mounted) problem(context, e);
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) problem(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> prepare() => act(() async {
    final ids = selected
        .where((id) => c.waiting.any((o) => o['id'] == id))
        .toList();
    if (ids.isEmpty) throw StateError('Pilih pesanan yang akan dimuat.');
    final route = await c.calculateRoute(ids.map(c.order).toList());
    if (!mounted) return;
    await openPage(
      context,
      TripPreparation(runtime: c, route: route, ids: ids),
    );
    selected.clear();
  });
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
    ),
  );
  Widget syncNotice() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.hasConflict
              ? 'Sinkronisasi perlu diperiksa · catatan lokal tersimpan'
              : '${groupedNumber(c.outbox.length)} perubahan menunggu sinkronisasi',
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
        if (c.blockedSyncReason != null)
          Text(c.blockedSyncReason!, style: const TextStyle(fontSize: 11)),
        if (c.syncError != null && !c.hasConflict)
          Text(c.syncError!, style: const TextStyle(fontSize: 11)),
        if (c.hasConflict)
          TextButton(
            onPressed: () => act(() async {
              await Clipboard.setData(
                ClipboardData(text: jsonEncode(await c.store.pending())),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Catatan konflik disalin; berisi data penerima.',
                    ),
                  ),
                );
              }
            }),
            child: const Text('Salin catatan konflik'),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Scaffold(
      appBar: tab == 0
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Kembali ke Home',
                onPressed: () => setState(() => tab = 0),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                [
                  '',
                  'Riwayat Pengantaran',
                  'Performa Kurir',
                  'Profil Mitra Kurir',
                ][tab],
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: BrandBadge(),
                ),
              ],
            ),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: ListView(
            key: ValueKey(tab),
            padding: const EdgeInsets.all(20),
            children: [
              if (tab == 0) ...[CourierIdentity(c), const SizedBox(height: 22)],
              if (c.isDemo)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'DEMO · Data contoh lokal',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ),
              if (c.outbox.isNotEmpty || c.syncError != null) syncNotice(),
              ...switch (tab) {
                0 => dashboard(),
                1 => history(),
                2 => performance(),
                _ => profile(),
              },
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FigcraftTabs(
            selected: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          if (tab == 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        busy ||
                            c.hasConflict ||
                            (c.activeTrip == null && selected.isEmpty)
                        ? null
                        : c.activeTrip != null
                        ? () => openPage(context, TripPage(runtime: c))
                        : prepare,
                    icon: Icon(
                      c.activeTrip == null
                          ? Icons.inventory_2_outlined
                          : Icons.navigation_outlined,
                    ),
                    label: Text(
                      busy
                          ? 'Menghitung jalan…'
                          : c.activeTrip != null
                          ? c.remaining.isEmpty
                                ? 'Kembali & Setor ke Depot'
                                : 'Lanjutkan Pengantaran'
                          : 'Mulai Muat Barang (${selected.length})',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  List<Widget> dashboard() => [
    DeliverySummary(c),
    const SizedBox(height: 22),
    Row(
      children: [
        const Expanded(
          child: Text(
            'Daftar Pesanan Siap Kirim',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Sinkronkan data',
          onPressed: c.syncing ? null : c.sync,
          icon: const Icon(Icons.sync, size: 20),
        ),
      ],
    ),
    Row(
      children: [
        Expanded(
          child: Text(
            '${c.waiting.length} pesanan dalam antrean',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
        TextButton.icon(
          onPressed: c.hasConflict
              ? null
              : () => openPage(context, OrderForm(runtime: c)),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah pesanan', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
    if (c.waiting.isEmpty)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Belum ada pesanan. Tambahkan pesanan untuk menyusun perjalanan.',
        ),
      ),
    for (final o in c.waiting)
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              secondary: const IsometricBox(size: 44),
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              value: selected.contains(o['id']),
              onChanged: busy || c.hasConflict || c.activeTrip != null
                  ? null
                  : (v) => setState(() {
                      if (v == true) {
                        selected.add(o['id']);
                      } else {
                        selected.remove(o['id']);
                      }
                    }),
              title: Text(
                o['recipient'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${groupedNumber(o['boxes'])} Box · ${o['items']}\n${o['address']}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rupiah(o['bill']),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy || c.hasConflict
                        ? null
                        : () => openPage(
                            context,
                            OrderForm(runtime: c, order: o),
                          ),
                    child: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: busy || c.hasConflict ? null : () => cancel(o),
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
  ];
  Future<void> cancel(Json o) => act(() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(
          'Pesanan ${o['recipient']} akan dikeluarkan dari antrean.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan pesanan'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await c.cancel(o['id']);
      selected.remove(o['id']);
    }
  });
  List<Widget> history() {
    final filtered = c.history.where((o) {
      final date = DateTime.parse(o['completedAt']).toLocal();
      return '${o['id']} ${o['recipient']}'.toLowerCase().contains(
            search.text.trim().toLowerCase(),
          ) &&
          (dates == null ||
              (!date.isBefore(dates!.start) &&
                  date.isBefore(dates!.end.add(const Duration(days: 1)))));
    }).toList();
    final cash = filtered
        .where((o) => o['payment']['method'] == 'cash')
        .fold<int>(0, (s, o) => s + (o['bill'] as int));
    final other = filtered
        .where((o) => o['payment']['method'] != 'cash')
        .fold<int>(0, (s, o) => s + (o['bill'] as int));
    return [
      Text(
        '${filtered.length} Pesanan Selesai · Cabang Pettarani',
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 16),
      InkPanel([
        const Text(
          'SETORAN KASIR CABANG',
          style: TextStyle(
            color: lime,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tunai / COD', style: TextStyle(fontSize: 10)),
                Text(
                  rupiah(cash),
                  style: const TextStyle(
                    color: lime,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Non-Tunai', style: TextStyle(fontSize: 10)),
                Text(
                  rupiah(other),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Divider(color: Color(0xFF3F3F46)),
        Text(
          'Total tagihan ${rupiah(cash + other)}',
          style: const TextStyle(fontSize: 11),
        ),
      ]),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SmallMetric(
            'Box Terantar',
            '${filtered.fold<int>(0, (s, o) => s + (o['boxes'] as int))} Box',
          ),
          SmallMetric(
            'Perjalanan disetor',
            '${c.trips.where((t) => t['settledAt'] != null).length}',
          ),
        ],
      ),
      const SizedBox(height: 20),
      TextField(
        controller: search,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Pencarian riwayat',
          hintText: 'Cari ID pesanan atau nama penerima',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      Row(
        children: [
          TextButton.icon(
            onPressed: () async {
              final value = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dates,
                helpText: 'Pilih tanggal',
              );
              if (mounted && value != null) setState(() => dates = value);
            },
            icon: const Icon(Icons.date_range, size: 17),
            label: const Text('Pilih tanggal'),
          ),
          if (dates != null)
            TextButton(
              onPressed: () => setState(() => dates = null),
              child: const Text('Hapus filter'),
            ),
        ],
      ),
      const Text(
        'Rincian Pengantaran',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        const Text('Belum ada pengantaran selesai yang cocok.'),
      for (final entry in filtered.indexed)
        Card(
          child: ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: ink,
              foregroundColor: lime,
              child: Text(
                '${entry.$1 + 1}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(
              entry.$2['recipient'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${dateLabel(entry.$2['completedAt'])}\n${entry.$2['items']}\n${rupiah(entry.$2['bill'])} · Lunas',
              style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () =>
                openPage(context, OrderDetail(runtime: c, order: entry.$2)),
          ),
        ),
      if (c.activeTrip != null && c.remaining.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: FilledButton(
            onPressed: () => openPage(context, TripPage(runtime: c)),
            child: const Text('Setor Tunai ke Kasir Depot'),
          ),
        ),
    ];
  }

  List<Json> get todayHistory => c.history
      .where(
        (o) => DateUtils.isSameDay(
          DateTime.parse(o['completedAt']).toLocal(),
          DateTime.now(),
        ),
      )
      .toList();
  List<Widget> performance() => [
    InkPanel([
      const Text(
        'RINGKASAN SHIFT HARI INI',
        style: TextStyle(
          color: lime,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '${todayHistory.fold<int>(0, (s, o) => s + (o['boxes'] as int))} Box Selesai',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: lime,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '${todayHistory.length} pesanan selesai hari ini',
        style: const TextStyle(fontSize: 11),
      ),
    ]),
    const SizedBox(height: 18),
    WeekChart(c.history),
    const SizedBox(height: 18),
    Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'UANG DITERIMA SHIFT INI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          for (final method in ['cash', 'qris', 'transfer'])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                {
                  'cash': 'Tunai / COD',
                  'qris': 'QRIS',
                  'transfer': 'Transfer',
                }[method]!,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                rupiah(
                  todayHistory
                      .where((o) => o['payment']['method'] == method)
                      .fold<int>(0, (s, o) => s + (o['bill'] as int)),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: method == 'cash' ? ink : const Color(0xFF047857),
                ),
              ),
            ),
        ],
      ),
    ),
  ];
  List<Widget> profile() => [
    InkPanel([
      Row(
        children: [
          CourierAvatar(c, radius: 27),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.fullName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: lime,
                  ),
                ),
                Text('@${c.username}', style: const TextStyle(fontSize: 11)),
                const Text(
                  'Kurir · Cabang Pettarani',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(color: Color(0xFF3F3F46)),
      Text(
        '${c.history.length} Pengantaran · ${c.trips.where((t) => t['settledAt'] != null).length} Perjalanan disetor',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ]),
    const SizedBox(height: 18),
    Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text(
              'WILAYAH OPERASIONAL & SHIFT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Makassar · Hub Pettarani',
              style: TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
            subtitle: Text(
              c.phone.isEmpty ? 'Belum diisi' : c.phone,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KEPATUHAN SOP BROWCYL MAKASSAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            Text(
              '✓ Muat LIFO sesuai rute\n✓ Periksa segel dan kondisi box\n✓ Setor tunai setelah kembali ke depot',
              style: TextStyle(fontSize: 12, height: 1.8),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: () => openPage(context, EditCourierProfile(runtime: c)),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit profil'),
    ),
    if (!c.isDemo) ...[
      TextButton(
        onPressed: busy
            ? null
            : () => act(() async {
                await c.backend.auth.resetPasswordForEmail(
                  c.backend.auth.currentUser!.email!,
                  redirectTo: authRedirect,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tautan perubahan password dikirim ke email.',
                      ),
                    ),
                  );
                }
              }),
        child: const Text('Ubah password melalui email'),
      ),
      OutlinedButton(
        onPressed: busy || c.outbox.isNotEmpty
            ? null
            : () => act(() async {
                await c.gps.stop();
                await c.backend.auth.signOut(scope: SignOutScope.local);
              }),
        child: const Text('Keluar'),
      ),
    ],
    if (c.isDemo)
      OutlinedButton(
        onPressed: busy
            ? null
            : () => act(() async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset data demo?'),
                    content: const Text(
                      'Semua perubahan demo diganti dengan data contoh awal.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (yes == true) {
                  await c.resetDemo();
                  selected.clear();
                }
              }),
        child: const Text('Reset data demo'),
      ),
    Text(
      c.isDemo
          ? 'Data demo lokal · tidak dikirim ke server'
          : '${c.outbox.length} perubahan menunggu sinkronisasi',
      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
    ),
    if (c.outbox.isNotEmpty)
      const Text(
        'Sinkronkan semua perubahan sebelum keluar agar catatan pengantaran tetap aman.',
        style: TextStyle(fontSize: 11),
      ),
  ];
}

class OrderDetail extends StatelessWidget {
  final CourierRuntime runtime;
  final Json order;
  const OrderDetail({required this.runtime, required this.order, super.key});
  @override
  Widget build(BuildContext context) {
    final p = order['payment'] as Json,
        t = runtime.trips.firstWhere((t) => t['id'] == order['tripId']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail pengantaran'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: BrandBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            order['recipient'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          for (final e in <String, String>{
            'ID pesanan': order['id'],
            'Alamat': order['address'],
            'WhatsApp': order['phone'],
            'Barang': '${order['items']} · ${order['boxes']} box',
            'Selesai': dateLabel(order['completedAt']),
            'Tagihan': rupiah(order['bill']),
            'Metode': p['method'],
            'Uang diterima': rupiah(p['received']),
            'Kembalian': rupiah(
              (p['received'] as int) - (order['bill'] as int),
            ),
            'Referensi': p['reference'] == '' ? 'Tunai' : p['reference'],
            'ID perjalanan': t['id'],
            'Setoran': dateLabel(t['settledAt']),
            'Sinkronisasi akun': runtime.isDemo
                ? 'Data demo lokal'
                : runtime.hasConflict
                ? 'Konflik'
                : runtime.outbox.isEmpty
                ? 'Tersinkron'
                : 'Menunggu sinkronisasi',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(e.value),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EditCourierProfile extends StatefulWidget {
  final CourierRuntime runtime;
  final XFile? recoveredPhoto;
  const EditCourierProfile({
    required this.runtime,
    this.recoveredPhoto,
    super.key,
  });
  @override
  State<EditCourierProfile> createState() => _EditCourierProfileState();
}

class _EditCourierProfileState extends State<EditCourierProfile> {
  late final name = TextEditingController(text: widget.runtime.fullName);
  late final phone = TextEditingController(text: widget.runtime.phone);
  final form = GlobalKey<FormState>();
  bool busy = false;
  Uint8List? photo;
  @override
  void initState() {
    super.initState();
    if (widget.recoveredPhoto != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await acceptPhoto(widget.recoveredPhoto!);
        } catch (e) {
          if (mounted) problem(context, e);
        }
      });
    }
  }

  Future<void> acceptPhoto(XFile file) async {
    final bytes = await prepareProfilePhoto(await file.readAsBytes());
    if (mounted) setState(() => photo = bytes);
  }

  Future<void> pickPhoto() async {
    setState(() => busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file != null) await acceptPhoto(file);
    } catch (e) {
      if (mounted) problem(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
            child: photo == null
                ? CourierAvatar(widget.runtime, radius: 36)
                : CircleAvatar(
                    radius: 36,
                    backgroundImage: MemoryImage(photo!),
                  ),
          ),
          TextButton.icon(
            onPressed: busy ? null : pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Ganti foto'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Profil Mitra Kurir',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Nama kurir',
              hintText: 'Masukkan Nama',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp',
              hintText: '081xxxx',
            ),
            validator: (v) => !RegExp(r'^0[0-9]{8,14}$').hasMatch(v ?? '')
                ? 'Gunakan 9–15 digit, diawali 0'
                : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() => busy = true);
                    try {
                      await widget.runtime.updateProfile(
                        name.text,
                        phone.text,
                        photo: photo,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) problem(context, e);
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(busy ? 'Menyimpan…' : 'Simpan profil'),
          ),
        ],
      ),
    ),
  );
}
