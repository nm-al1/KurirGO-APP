import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/waypoint_model.dart';

typedef LinkOpener = Future<bool> Function(Uri uri);
Future<bool> openExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
String normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
}

Uri callUri(String phone) =>
    Uri(scheme: 'tel', path: '+${normalizePhone(phone)}');
Uri chatUri(String phone) => Uri.https('wa.me', '/${normalizePhone(phone)}');
Uri mapsUri(WaypointModel point, {LatLng? origin}) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': '${point.latitude},${point.longitude}',
  'travelmode': 'driving',
  'dir_action': 'navigate',
  if (origin != null) 'origin': '${origin.latitude},${origin.longitude}',
});

Future<void> launchCourierLink(
  BuildContext context,
  Uri uri,
  String fallback, {
  LinkOpener opener = openExternal,
}) async {
  var opened = false;
  try {
    opened = await opener(uri);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Aplikasi tidak dapat dibuka. Salin kontak atau tujuan.',
        ),
        action: SnackBarAction(
          label: 'Salin',
          onPressed: () => Clipboard.setData(ClipboardData(text: fallback)),
        ),
      ),
    );
  }
}
