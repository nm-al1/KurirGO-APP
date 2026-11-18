
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

Future<Uint8List> prepareProfilePhoto(Uint8List bytes) =>
    compute(_encode, bytes);

Uint8List _encode(Uint8List bytes) {
  if (bytes.length > 20 * 1024 * 1024) {
    throw StateError('Pilih foto di bawah 20 MB.');
  }
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Foto tidak dapat dibaca. Pilih JPG atau PNG.');
  }
  final oriented = image.bakeOrientation(decoded);
  final resized = oriented.width > 512 || oriented.height > 512
      ? image.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 512 : null,
          height: oriented.height > oriented.width ? 512 : null,
        )
      : oriented;
  // Re-encode pixels without EXIF (including the original photo's GPS metadata).
  resized.exif.clear();
  return Uint8List.fromList(image.encodeJpg(resized, quality: 85));
}
