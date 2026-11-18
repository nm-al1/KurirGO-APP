class WaypointModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int nodeIndex;

  const WaypointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.nodeIndex,
  });

  bool get isDepot => nodeIndex == 0;
}
