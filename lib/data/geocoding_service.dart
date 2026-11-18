import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/map_provider.dart';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PlaceLocation {
  final LatLng? point;
  final String? address;
  final String? placeId;
  const PlaceLocation(this.point, this.address, {this.placeId});
}

class GeocodingService {
  final SupabaseClient backend;
  final bool demo;
  final bool google;
  final http.Client client = http.Client();
  String _session = const Uuid().v4();
  GeocodingService(
    this.backend, {
    this.demo = false,
    this.google = useGoogleMaps,
  });
  Future<List<PlaceLocation>> search(String query) =>
      request({'query': query, 'sessionToken': _session});
  Future<PlaceLocation> resolve(PlaceLocation suggestion) async {
    if (suggestion.placeId == null) return suggestion;
    try {
      final found = await request({
        'placeId': suggestion.placeId,
        'sessionToken': _session,
      });
      if (found.isEmpty || found.first.point == null) {
        throw StateError('Lokasi belum dapat dimuat. Pilih kembali tempat.');
      }
      return found.first;
    } finally {
      _session = const Uuid().v4();
    }
  }

  Future<PlaceLocation?> reverse(LatLng point) async {
    final results = await request({
      'lat': point.latitude,
      'lng': point.longitude,
    });
    return results.isEmpty ? null : results.first;
  }

  Future<List<PlaceLocation>> request(Map<String, dynamic> input) async {
    if (demo) {
      const key = String.fromEnvironment('GEOAPIFY_DEMO_KEY');
      if (google || key.isEmpty) {
        throw StateError(
          'Pencarian demo belum dikonfigurasi. Pilih pin dan isi alamat manual.',
        );
      }
      final search = input.containsKey('query');
      final uri = Uri.https(
        'api.geoapify.com',
        '/v1/geocode/${search ? 'autocomplete' : 'reverse'}',
        {
          'apiKey': key,
          'format': 'json',
          'lang': 'id',
          if (search) ...{
            'text': input['query'],
            'filter': 'countrycode:id',
            'bias': 'proximity:119.435,-5.156',
            'limit': '5',
          } else ...{
            'lat': '${input['lat']}',
            'lon': '${input['lng']}',
          },
        },
      );
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw StateError('Pencarian alamat belum tersedia. Coba lagi nanti.');
      }
      return parse(jsonDecode(response.body));
    }
    try {
      final response = await backend.functions
          .invoke(google ? 'google-geocode' : 'geocode', body: input)
          .timeout(const Duration(seconds: 25));
      return parse(response.data);
    } on FunctionException catch (e) {
      throw StateError(
        e.details is Map
            ? e.details['error'] ?? 'Layanan alamat belum tersedia.'
            : 'Layanan alamat belum tersedia.',
      );
    } catch (_) {
      throw StateError(
        'Alamat belum dapat dimuat. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  static List<PlaceLocation> parse(dynamic body) {
    final values = body is Map ? body['results'] as List? ?? [] : [];
    return values
        .whereType<Map>()
        .where(
          (v) =>
              (v['placeId'] is String && v['lat'] == null) ||
              (v['lat'] is num &&
                  v['lon'] is num &&
                  (v['lat'] as num).isFinite &&
                  (v['lon'] as num).isFinite &&
                  (v['lat'] as num).abs() <= 90 &&
                  (v['lon'] as num).abs() <= 180),
        )
        .map(
          (v) => PlaceLocation(
            v['lat'] == null
                ? null
                : LatLng(
                    (v['lat'] as num).toDouble(),
                    (v['lon'] as num).toDouble(),
                  ),
            v['formatted'] as String?,
            placeId: v['placeId'] as String?,
          ),
        )
        .toList();
  }

  void dispose() => client.close();
}
