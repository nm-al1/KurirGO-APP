import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kurir_go/features/shared/map_tile_scope.dart';

class OfflineTileProvider extends TileProvider {
  static final image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGN49OLDfwAJJAO6qMY5tAAAAABJRU5ErkJggg==',
    ),
  );
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      image;
}

Widget offlineMaps(Widget child) =>
    MapTileScope(create: OfflineTileProvider.new, child: child);
