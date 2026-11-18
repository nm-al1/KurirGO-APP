import '../../core/map_provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as g;

import '../shared/google_map_gate.dart';
import '../shared/map_tile_scope.dart';

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../../data/geocoding_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/number_format.dart';
import '../../data/courier_store.dart';
import '../controllers/courier_runtime.dart';
import 'app.dart';

class OrderForm extends StatefulWidget {
  final CourierRuntime runtime;
  final Json? order;
  const OrderForm({required this.runtime, this.order, super.key});
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final form = GlobalKey<FormState>();
  static const keys = [
    'recipient',
    'phone',
    'address',
    'items',
    'boxes',
    'bill',
  ];
  static const labels = [
    'Penerima',
    'WhatsApp',
    'Alamat',
    'Rincian barang',
    'Jumlah box',
    'Tagihan',
  ];
  static const hints = [
    'Bapak/Ibu',
    '081xxxx',
    'Nama jalan, nomor bangunan, dan patokan',
    'Contoh: Brownies cokelat 3 box',
    'Contoh: 3',
    'Contoh: 150.000',
  ];
  late final fields = List.generate(
    6,
    (i) => TextEditingController(
      text: widget.order == null
          ? ''
          : i == 4 || i == 5
          ? groupedNumber(widget.order![keys[i]] as num)
          : '${widget.order![keys[i]]}',
    ),
  );
  late LatLng? point = widget.order == null
      ? null
      : LatLng(
          (widget.order!['lat'] as num).toDouble(),
          (widget.order!['lng'] as num).toDouble(),
        );
  bool busy = false;
  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    if (point == null) {
      problem(context, StateError('Pilih lokasi penerima di peta.'));
      return;
    }
    setState(() => busy = true);
    try {
      await widget.runtime.saveOrder({
        for (var i = 0; i < keys.length; i++)
          keys[i]: i == 4 || i == 5
              ? parseWholeNumber(fields[i].text)
              : fields[i].text.trim(),
        'lat': point!.latitude,
        'lng': point!.longitude,
      }, id: widget.order?['id']);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) problem(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.order == null ? 'Tambah pesanan' : 'Edit pesanan'),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.runtime.activeTrip != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text('Pesanan baru masuk antrean perjalanan berikutnya.'),
            ),
          for (var i = 0; i < keys.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextFormField(
                controller: fields[i],
                minLines: i == 2 || i == 3 ? 2 : 1,
                maxLines: i == 2 || i == 3 ? 3 : 1,
                keyboardType: i == 1
                    ? TextInputType.phone
                    : i >= 4
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: i == 4 || i == 5
                    ? [const IndonesianIntegerFormatter()]
                    : null,
                decoration: InputDecoration(
                  labelText: labels[i],
                  hintText: hints[i],
                  prefixText: i == 5 ? 'Rp ' : null,
                ),
                validator: (text) {
                  if (text == null || text.trim().isEmpty) {
                    return '${labels[i]} wajib diisi';
                  }
                  final limit = CourierRuntime.orderTextLimits[keys[i]];
                  if (limit != null && text.trim().runes.length > limit) {
                    return 'Maksimal $limit karakter';
                  }
                  if (i == 1 && !RegExp(r'^0[0-9]{8,14}$').hasMatch(text)) {
                    return 'Gunakan 9–15 digit, diawali 0';
                  }
                  if (i == 4 &&
                      (parseWholeNumber(text) == null ||
                          parseWholeNumber(text)! < 1 ||
                          parseWholeNumber(text)! > 9999)) {
                    return 'Jumlah box harus 1–9.999';
                  }
                  if (i == 5 && parseWholeNumber(text) == null) {
                    return 'Isi nominal rupiah tanpa desimal';
                  }
                  return null;
                },
              ),
            ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final selected = await openPage<PlaceLocation>(
                      context,
                      PinPage(
                        initial: point ?? const LatLng(-5.1560, 119.4350),
                        service: GeocodingService(
                          widget.runtime.backend,
                          demo: widget.runtime.isDemo,
                        ),
                      ),
                    );
                    if (selected != null && mounted) {
                      setState(() => point = selected.point);
                      fields[2].text = selected.address ?? '';
                    }
                  },
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              point == null ? 'Pilih pin di peta' : 'Ubah lokasi di peta',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Menyimpan…' : 'Simpan pesanan'),
          ),
        ],
      ),
    ),
  );
}

class PinPage extends StatefulWidget {
  final LatLng initial;
  final GeocodingService service;
  const PinPage({required this.initial, required this.service, super.key});
  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final map = MapController();
  g.GoogleMapController? googleMap;
  LatLng? cameraPoint;
  bool programmaticMove = false, resolving = false;
  LatLng? suppressedTarget;
  final search = TextEditingController();
  late LatLng point = widget.initial;
  String? address, message;
  List<PlaceLocation> results = [];
  Timer? searchTimer, pinTimer;
  int searchGeneration = 0, pinGeneration = 0;
  bool searching = false, locating = false, tileFailed = false;
  @override
  void initState() {
    super.initState();
    locate(point);
  }

  Future<void> locate(LatLng value) async {
    final generation = ++pinGeneration;
    setState(() {
      point = value;
      address = null;
      locating = true;
      message = null;
    });
    try {
      final found = await widget.service.reverse(value);
      if (!mounted || generation != pinGeneration) return;
      setState(() {
        address = found?.address;
        message = address == null
            ? 'Alamat belum ditemukan. Isi alamat manual setelah memilih pin.'
            : null;
      });
    } catch (e) {
      if (mounted && generation == pinGeneration) {
        setState(
          () => message =
              'Alamat belum termuat. Coba geser pin, atau isi alamat manual.',
        );
      }
    } finally {
      if (mounted && generation == pinGeneration) {
        setState(() => locating = false);
      }
    }
  }

  void moved(LatLng value) {
    pinTimer?.cancel();
    ++pinGeneration;
    setState(() {
      point = value;
      address = null;
      locating = true;
      message = null;
    });
    pinTimer = Timer(const Duration(milliseconds: 600), () => locate(value));
  }

  void changed(String query) {
    searchTimer?.cancel();
    final generation = ++searchGeneration;
    setState(() {
      results = [];
      searching = false;
      message = null;
    });
    if (query.trim().length < 3) return;
    searchTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => searching = true);
      try {
        final found = await widget.service.search(query.trim());
        if (mounted && generation == searchGeneration) {
          setState(() {
            results = found;
            message = found.isEmpty
                ? 'Lokasi tidak ditemukan. Coba nama jalan atau tempat lain.'
                : null;
          });
        }
      } catch (e) {
        if (mounted && generation == searchGeneration) {
          setState(
            () => message = e.toString().replaceFirst('Bad state: ', ''),
          );
        }
      } finally {
        if (mounted && generation == searchGeneration) {
          setState(() => searching = false);
        }
      }
    });
  }

  Future<void> choose(PlaceLocation suggestion) async {
    FocusScope.of(context).unfocus();
    ++searchGeneration;
    pinTimer?.cancel();
    final generation = ++pinGeneration;
    setState(() {
      results = [];
      searching = false;
      locating = true;
      resolving = true;
      address = null;
    });
    try {
      final selected = await widget.service.resolve(suggestion);
      if (!mounted || generation != pinGeneration || selected.point == null) {
        return;
      }
      programmaticMove = true;
      suppressedTarget = selected.point;
      if (!useGoogleMaps || MapTileScope.of(context) != null) {
        map.move(selected.point!, 17);
      } else {
        await googleMap?.animateCamera(
          g.CameraUpdate.newLatLngZoom(
            g.LatLng(selected.point!.latitude, selected.point!.longitude),
            17,
          ),
        );
      }
      if (!mounted || generation != pinGeneration) return;
      setState(() {
        point = selected.point!;
        address = selected.address;
        message = null;
        locating = false;
      });
    } catch (e) {
      if (mounted && generation == pinGeneration) {
        setState(() {
          message = e.toString().replaceFirst('Bad state: ', '');
          locating = false;
        });
      }
    } finally {
      programmaticMove = false;
      if (mounted) setState(() => resolving = false);
    }
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    pinTimer?.cancel();
    search.dispose();
    map.dispose();
    googleMap?.dispose();
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pilih lokasi penerima')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: search,
            onChanged: changed,
            decoration: const InputDecoration(
              labelText: 'Cari lokasi',
              hintText: 'Cari tempat atau nama jalan',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        if (searching) const LinearProgressIndicator(),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(message!),
          ),
        if (tileFailed)
          const Text('Peta belum termuat. Periksa koneksi internet.'),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (useGoogleMaps && MapTileScope.of(context) == null)
                GoogleMapGate(
                  child: Listener(
                    onPointerDown: (_) => suppressedTarget = null,
                    child: g.GoogleMap(
                      initialCameraPosition: g.CameraPosition(
                        target: g.LatLng(point.latitude, point.longitude),
                        zoom: 14,
                      ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (value) => googleMap = value,
                      onTap: (value) {
                        final selected = LatLng(
                          value.latitude,
                          value.longitude,
                        );
                        programmaticMove = true;
                        suppressedTarget = selected;
                        googleMap
                            ?.moveCamera(g.CameraUpdate.newLatLng(value))
                            .whenComplete(() => programmaticMove = false);
                        moved(selected);
                      },
                      onCameraMove: (position) {
                        cameraPoint = LatLng(
                          position.target.latitude,
                          position.target.longitude,
                        );
                        if (!programmaticMove &&
                            cameraPoint != suppressedTarget) {
                          pinTimer?.cancel();
                          ++pinGeneration;
                          setState(() {
                            locating = true;
                            address = null;
                          });
                        }
                      },
                      onCameraIdle: () {
                        if (!programmaticMove &&
                            cameraPoint != null &&
                            cameraPoint != suppressedTarget) {
                          moved(cameraPoint!);
                        }
                      },
                    ),
                  ),
                )
              else
                FlutterMap(
                  mapController: map,
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 14,
                    onTap: (_, value) {
                      map.move(value, map.camera.zoom);
                      moved(value);
                    },
                    onPositionChanged: (camera, gesture) {
                      if (gesture) moved(camera.center);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.browcyl.kurir_go',
                      errorTileCallback: (_, _, _) {
                        if (!tileFailed) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => tileFailed = true);
                          });
                        }
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text(
                            'OpenStreetMap contributors',
                            style: TextStyle(fontSize: 11),
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (results.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.25,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: results
                            .map(
                              (place) => ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(place.address ?? 'Lokasi pilihan'),
                                onTap: resolving ? null : () => choose(place),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              const IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.location_pin, size: 40, color: ink),
                ),
              ),
            ],
          ),
        ),
        if (MediaQuery.viewInsetsOf(context).bottom == 0)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locating
                        ? 'Mencari alamat...'
                        : address ??
                              'Pin dipilih - lengkapi alamat setelah ini',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        useGoogleMaps
                            ? 'https://maps.google.com/'
                            : 'https://www.geoapify.com/',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      useGoogleMaps ? 'Google Maps' : 'Powered by Geoapify',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: locating
                        ? null
                        : () => Navigator.pop(
                            context,
                            PlaceLocation(point, address),
                          ),
                    child: const Text('Gunakan lokasi ini'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
