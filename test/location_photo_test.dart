import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kurir_go/data/geocoding_service.dart';
import 'package:kurir_go/data/profile_photo.dart';

void main() {
  test('geocoding rejects invalid points and retains address', () {
    final found = GeocodingService.parse({
      'results': [
        {'lat': -5.156, 'lon': 119.435, 'formatted': 'Makassar'},
        {'lat': 95, 'lon': 119},
        {'lat': 'bad', 'lon': 119},
      ],
    });
    expect(found.length, 1);
    expect(found.single.address, 'Makassar');
    expect(found.single.point!.latitude, -5.156);
  });
  test('profile photo is valid JPEG within avatar dimensions', () async {
    final original = image.Image(width: 1000, height: 600);
    final bytes = await prepareProfilePhoto(
      Uint8List.fromList(image.encodePng(original)),
    );
    final decoded = image.decodeJpg(bytes)!;
    expect(decoded.width, 512);
    expect(decoded.height, 307);
    expect(bytes.length, lessThan(2097152));
  });
  test('invalid photo fails before upload', () async {
    await expectLater(
      prepareProfilePhoto(Uint8List.fromList([1, 2, 3])),
      throwsStateError,
    );
  });
}
