import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleMapGate extends StatefulWidget {
  final Widget child;
  const GoogleMapGate({required this.child, super.key});
  @override
  State<GoogleMapGate> createState() => _GoogleMapGateState();
}

class _GoogleMapGateState extends State<GoogleMapGate> {
  late final ready = configured();
  Future<bool> configured() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await const MethodChannel('kurirgo/maps')
              .invokeMethod<bool>('configured') ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: ready,
    builder: (context, snapshot) => snapshot.data == true
        ? widget.child
        : const ColoredBox(
            color: Color(0xFFE2E8F0),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Google Maps belum tersedia. Periksa konfigurasi aplikasi Android.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
  );
}
