import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/dummy_makassar_data.dart';
import '../../data/models/waypoint_model.dart';
import '../../data/models/road_route.dart';
import '../controllers/navigation_simulation_controller.dart';
import '../controllers/gps_navigation.dart';
import 'rider_puck.dart';

List<Widget> roadMapLayers(
  RoadRoute route,
  NavigationSimulationController? simulation, [
  List<WaypointModel>? waypoints,
  GpsNavigation? gps,
]) => [
  if (gps?.fix != null)
    CircleLayer(
      circles: [
        CircleMarker(
          point: gps!.fix!.point,
          radius: gps.fix!.accuracy.clamp(1, 500),
          useRadiusInMeter: true,
          color: const Color(0x223B82F6),
          borderColor: const Color(0xFF475569),
          borderStrokeWidth: 1,
        ),
      ],
    ),
  PolylineLayer(
    polylines: [
      for (final entry in route.legs.indexed)
        Polyline(
          points: entry.$2.points,
          strokeWidth: 6,
          color:
              (gps != null
                  ? entry.$1 == gps.legIndex
                  : simulation == null || simulation.leg == entry.$2)
              ? const Color(0xFFC6FF00)
              : const Color(0xFF64748B),
          borderStrokeWidth: 3,
          borderColor: const Color(0xFF18181B),
        ),
    ],
  ),
  MarkerLayer(
    markers: [
      for (final point in waypoints ?? DummyMakassarData.waypoints)
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 42,
          height: 42,
          child: Tooltip(
            message: point.name,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC6FF00), width: 3),
              ),
              child: Text(
                waypoints != null
                    ? (point.nodeIndex == 0 ? 'V0' : '#${point.nodeIndex}')
                    : point.nodeIndex == 0
                    ? 'V0'
                    : point.nodeIndex == 2
                    ? '#1'
                    : '#2',
                style: const TextStyle(
                  color: Color(0xFFC6FF00),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      if (simulation != null)
        Marker(
          point: simulation.position,
          width: 64,
          height: 64,
          child: RiderPuck(
            heading: simulation.heading,
            moving: simulation.running,
          ),
        ),
      if (gps?.fix != null)
        Marker(
          point: gps!.fix!.point,
          width: 64,
          height: 64,
          child: RiderPuck(
            heading: gps.fix!.heading.isFinite && gps.fix!.heading >= 0
                ? gps.fix!.heading
                : 0,
            moving: gps.reliable && gps.fix!.speed > 0.5,
          ),
        ),
    ],
  ),
];
