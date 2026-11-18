import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Supplies a tile source to embedded maps, including offline widget previews.
class MapTileScope extends InheritedWidget {
  final TileProvider Function() create;
  const MapTileScope({required this.create, required super.child, super.key});
  static MapTileScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MapTileScope>();
  @override
  bool updateShouldNotify(MapTileScope oldWidget) => create != oldWidget.create;
}
