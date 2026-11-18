import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../data/courier_store.dart';
import '../../data/models/road_route.dart';
import '../../data/models/waypoint_model.dart';
import '../controllers/courier_runtime.dart';
import '../controllers/navigation_simulation_controller.dart';
import '../shared/makassar_map_view.dart';
import '../shared/external_actions.dart';
import '../shared/presentation.dart' show rupiah;
import '../shared/isometric_box.dart';
import 'figcraft_widgets.dart';
import 'app.dart';

List<WaypointModel> tripWaypoints(CourierRuntime runtime, Json route) {
  final coordinates = route['geometry']['inputCoordinates'] as List;
  final stops = route['stops'] as List;
  return [
    for (var i = 0; i < coordinates.length - 1; i++)
      WaypointModel(
        id: i == 0 ? 'depot' : stops[i - 1].first as String,
        name: i == 0
            ? 'Depot Browcyl'
            : runtime.order(stops[i - 1].first)['recipient'],
        address: i == 0
            ? 'Depot Browcyl, Makassar'
            : runtime.order(stops[i - 1].first)['address'],
        latitude: (coordinates[i][1] as num).toDouble(),
        longitude: (coordinates[i][0] as num).toDouble(),
        nodeIndex: i,
      ),
  ];
}

class TripPreparation extends StatefulWidget {
  final CourierRuntime runtime;
  final Json route;
  final List<String> ids;
  const TripPreparation({
    required this.runtime,
    required this.route,
    required this.ids,
    super.key,
  });
  @override
  State<TripPreparation> createState() => _TripPreparationState();
}

class _TripPreparationState extends State<TripPreparation> {
  final verified = <String>{};
  bool busy = false;
  bool preview = false;
  late final road = RoadRoute.fromJson(widget.route['geometry']);
  @override
  Widget build(BuildContext context) {
    final ids = (widget.route['stops'] as List)
        .expand((s) => s as List)
        .cast<String>()
        .toList();
    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        title: Text(preview ? 'Preview Rute Loop' : 'Verifikasi Muatan Box'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: preview ? ink : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (preview)
              SizedBox(
                height: 380,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MakassarMapView(
                    route: road,
                    waypoints: tripWaypoints(widget.runtime, widget.route),
                  ),
                ),
              ),
            SizedBox(height: preview ? 20 : 0),
            if (preview)
              Text(
                '${decimalNumber((widget.route['distance'] as num) / 1000)} km · ${groupedNumber(((widget.route['duration'] as num) / 60).ceil())} menit',
                style: const TextStyle(
                  color: lime,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (preview)
              Text(
                '${widget.route['algorithm']} · Optimasi total jarak · berangkat dan kembali ke depot',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            SizedBox(height: preview ? 24 : 0),
            if (!preview)
              const Text(
                'Susun muatan dari bawah',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 8),
            if (!preview)
              const Text(
                'Masukkan pesanan terakhir lebih dahulu. Pesanan tujuan pertama berada paling atas dan dikeluarkan pertama (LIFO).',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            const SizedBox(height: 16),
            if (!preview)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Periksa fisik box, segel, dan susunan bagasi sebelum mulai.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ),
            if (!preview)
              for (final entry in ids.reversed.indexed)
                Card(
                  child: CheckboxListTile(
                    secondary: const IsometricBox(size: 42),
                    contentPadding: const EdgeInsets.all(12),
                    value: verified.contains(entry.$2),
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            if (value == true) {
                              verified.add(entry.$2);
                            } else {
                              verified.remove(entry.$2);
                            }
                          }),
                    title: Text(
                      '${entry.$1 + 1}. ${widget.runtime.order(entry.$2)['recipient']}',
                    ),
                    subtitle: Text(
                      '${widget.runtime.order(entry.$2)['items']} · ${groupedNumber(widget.runtime.order(entry.$2)['boxes'])} box${entry.$1 == ids.length - 1 ? ' · Paling atas' : ''}',
                    ),
                  ),
                ),
            if (preview) ...[
              const SizedBox(height: 16),
              for (final entry in ids.indexed)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lime,
                    foregroundColor: ink,
                    child: Text('${entry.$1 + 1}'),
                  ),
                  title: Text(
                    widget.runtime.order(entry.$2)['recipient'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    widget.runtime.order(entry.$2)['address'],
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ),
              const ListTile(
                leading: Icon(Icons.warehouse_outlined, color: lime),
                title: Text(
                  'FINISH · Kembali ke Depot Pettarani',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: busy || verified.length != ids.length
              ? null
              : () async {
                  if (!preview) {
                    setState(() => preview = true);
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await widget.runtime.startTrip(widget.route, widget.ids);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => TripPage(runtime: widget.runtime),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) problem(context, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(
            busy
                ? 'Menyimpan rute…'
                : preview
                ? 'Mulai Navigasi Langsung'
                : 'Urutkan Rute Loop (TSP)',
          ),
        ),
      ),
    );
  }
}

class TripPage extends StatefulWidget {
  final CourierRuntime runtime;
  const TripPage({required this.runtime, super.key});
  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> with WidgetsBindingObserver {
  late final Json trip = widget.runtime.activeTrip!;
  late final RoadRoute road = RoadRoute.fromJson(trip['geometry']);
  late final points = tripWaypoints(widget.runtime, trip);
  NavigationSimulationController? simulation;
  Timer? ticker;
  int currentLeg = -1;
  bool busy = false, nonCashConfirmed = false, depotConfirmed = false;
  bool useGps = true;
  String? method;
  final received = TextEditingController(), reference = TextEditingController();
  CourierRuntime get c => widget.runtime;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(refresh);
    useGps = true;
    refresh();
    if (useGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await c.prepareGps();
        if (mounted) await c.gps.start();
      });
    }
    ticker = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => simulation?.advance(const Duration(milliseconds: 50)),
    );
  }

  void refresh() {
    final stops = trip['stops'] as List;
    var index = stops.indexWhere(
      (stop) =>
          (stop as List).any((id) => c.order(id)['status'] != 'completed'),
    );
    if (index < 0) index = stops.length;
    if (currentLeg != index) {
      simulation?.dispose();
      currentLeg = index;
      simulation = NavigationSimulationController(road.legs[index]);
      unawaited(c.prepareGps());
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) simulation?.pause();
  }

  @override
  void dispose() {
    c.removeListener(refresh);
    WidgetsBinding.instance.removeObserver(this);
    ticker?.cancel();
    simulation?.dispose();
    received.dispose();
    reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = c.remaining.firstOrNull;
    final order = id == null ? null : c.order(id);
    final destination = id == null ? points.first : points[currentLeg + 1];
    return ListenableBuilder(
      listenable: c.gps,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.62 < 420
                    ? 420
                    : MediaQuery.sizeOf(context).height * 0.62,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MakassarMapView(
                        route: road,
                        waypoints: points,
                        simulation: useGps ? null : simulation,
                        gps: useGps ? c.gps : null,
                        mode: MapDisplayMode.navigation,
                        riderOffset: const Offset(0, 60),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 16,
                      right: 16,
                      child: Theme(
                        data: figcraftDarkTheme(context),
                        child: InkPanel([
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Kembali',
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back, color: lime),
                              ),
                              Expanded(
                                child: Text(
                                  id == null
                                      ? 'KEMBALI KE DEPOT'
                                      : 'STOP #${currentLeg + 1} · ${destination.name}',
                                  style: const TextStyle(
                                    color: lime,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ListenableBuilder(
                            listenable: simulation!,
                            builder: (context, _) => Text(
                              useGps
                                  ? c.gps.instruction
                                  : simulation!.instruction,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              Theme(
                data: figcraftDarkTheme(context),
                child: InkPanel([
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destination.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      useGps ? c.gps.status : 'Navigasi · Mode simulasi',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: [
                      if (useGps) ...[
                        Text(
                          c.gps.instruction,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(c.gps.status),
                        if (c.gps.reliable && c.gps.leg != null)
                          Text(
                            '${decimalNumber((c.gps.leg!.length - c.gps.progress) / 1000)} km tersisa pada ruas ini',
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: c.gps.starting
                                  ? null
                                  : () async {
                                      if (c.gps.enabled) {
                                        await c.gps.stop();
                                      } else {
                                        await c.prepareGps();
                                        await c.gps.start();
                                      }
                                    },
                              child: Text(
                                c.gps.enabled ? 'Hentikan GPS' : 'Aktifkan GPS',
                              ),
                            ),
                            TextButton(
                              onPressed: Geolocator.openLocationSettings,
                              child: const Text('Pengaturan lokasi'),
                            ),
                            TextButton(
                              onPressed: Geolocator.openAppSettings,
                              child: const Text('Izin aplikasi'),
                            ),
                          ],
                        ),
                      ] else
                        ListenableBuilder(
                          listenable: simulation!,
                          builder: (context, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                simulation!.instruction,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${decimalNumber(simulation!.remaining / 1000)} km tersisa pada ruas ini',
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      simulation!.running
                                          ? simulation!.pause()
                                          : simulation!.play();
                                    },
                                    icon: Icon(
                                      simulation!.running
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    label: Text(
                                      simulation!.running
                                          ? 'Jeda simulasi'
                                          : 'Putar simulasi',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: simulation!.replay,
                                    child: const Text('Ulangi simulasi'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (!useGps)
                        const Text(
                          'Posisi rider adalah simulasi, bukan GPS perangkat.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      if (c.isDemo)
                        TextButton(
                          onPressed: () async {
                            simulation?.pause();
                            setState(() => useGps = !useGps);
                            if (useGps) {
                              await c.prepareGps();
                              await c.gps.start();
                            } else {
                              await c.gps.stop();
                            }
                          },
                          child: Text(
                            useGps ? 'Gunakan simulasi demo' : 'Gunakan GPS HP',
                          ),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => launchCourierLink(
                          context,
                          mapsUri(destination),
                          destination.address,
                        ),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Buka navigasi Google Maps'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (order != null) ...[
                    if (c.isDemo)
                      const Text(
                        'Data contoh · telepon dan WhatsApp dinonaktifkan.',
                      ),
                    Text(
                      '${order['items']} · ${groupedNumber(order['boxes'])} box',
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: c.isDemo
                              ? null
                              : () => launchCourierLink(
                                  context,
                                  callUri(order['phone']),
                                  order['phone'],
                                ),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Telepon'),
                        ),
                        TextButton.icon(
                          onPressed: c.isDemo
                              ? null
                              : () => launchCourierLink(
                                  context,
                                  chatUri(order['phone']),
                                  order['phone'],
                                ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('WhatsApp'),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      'Tagihan ${rupiah(order['bill'])}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: const Text(
                        'Pilih metode pembayaran',
                        style: TextStyle(color: Color(0xFFA1A1AA)),
                      ),
                      initialValue: method,
                      decoration: const InputDecoration(
                        labelText: 'Metode pembayaran',
                        hintText: 'Pilih metode pembayaran',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Tunai / COD'),
                        ),
                        DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Transfer'),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => setState(() {
                              method = value;
                              nonCashConfirmed = false;
                              received.clear();
                              reference.clear();
                            }),
                    ),
                    const SizedBox(height: 24),
                    if (method == 'cash') ...[
                      TextField(
                        controller: received,
                        keyboardType: TextInputType.number,
                        inputFormatters: [const IndonesianIntegerFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Uang diterima',
                          hintText: 'Contoh: 150.000',
                          prefixText: 'Rp ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final amount in {
                            (order['bill'] as int),
                            50000,
                            100000,
                            150000,
                            200000,
                          })
                            ActionChip(
                              label: Text(
                                amount == order['bill']
                                    ? 'Uang pas'
                                    : rupiah(amount),
                              ),
                              onPressed: busy
                                  ? null
                                  : () => setState(
                                      () =>
                                          received.text = groupedNumber(amount),
                                    ),
                            ),
                        ],
                      ),
                      Text(
                        'Kembalian ${rupiah(((parseWholeNumber(received.text) ?? 0) - (order['bill'] as int)).clamp(0, maxRupiah))}',
                      ),
                    ],
                    if (method == 'qris' || method == 'transfer') ...[
                      const Text(
                        'Periksa bukti pembayaran pada rekening/QRIS resmi Browcyl sebelum mengonfirmasi.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reference,
                        decoration: const InputDecoration(
                          labelText: 'Referensi transaksi',
                          hintText: 'Contoh: TRX-99881',
                        ),
                      ),
                      CheckboxListTile(
                        value: nonCashConfirmed,
                        onChanged: busy
                            ? null
                            : (v) =>
                                  setState(() => nonCashConfirmed = v ?? false),
                        title: const Text(
                          'Pembayaran sudah masuk dan telah saya periksa',
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed:
                          busy ||
                              c.hasConflict ||
                              method == null ||
                              (method != 'cash' && !nonCashConfirmed)
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                await c.deliver(
                                  id!,
                                  method!,
                                  parseWholeNumber(received.text),
                                  reference.text,
                                );
                                setState(() {
                                  method = null;
                                  received.clear();
                                  reference.clear();
                                  nonCashConfirmed = false;
                                });
                              } catch (e) {
                                if (context.mounted) problem(context, e);
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      child: Text(
                        busy
                            ? 'Menyimpan…'
                            : 'Barang diterima, selesaikan pesanan',
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Total tunai untuk disetor: ${rupiah(c.orders.where((o) => o['tripId'] == trip['id'] && o['payment']?['method'] == 'cash').fold<int>(0, (sum, o) => sum + (o['bill'] as int)))}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    CheckboxListTile(
                      value: depotConfirmed,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => depotConfirmed = v ?? false),
                      title: const Text(
                        'Saya sudah kembali ke depot dan menyerahkan setoran',
                      ),
                    ),
                    FilledButton(
                      onPressed: busy || !depotConfirmed || c.hasConflict
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                await c.settle();
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) problem(context, e);
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      child: const Text(
                        'Konfirmasi setoran & tutup perjalanan',
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
