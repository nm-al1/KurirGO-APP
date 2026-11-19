import '../../core/map_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/road_route.dart';
import '../../data/models/waypoint_model.dart';
import '../controllers/navigation_simulation_controller.dart';
import '../controllers/gps_navigation.dart';
import 'map_controls.dart';
import 'google_route_view.dart';
import 'map_tile_scope.dart';
import 'road_map_layers.dart';
import 'map_attribution.dart';

enum MapDisplayMode { preview, navigation }

class MakassarMapView extends StatefulWidget {
  final RoadRoute route;
  final GpsNavigation? gps;
  final List<WaypointModel>? waypoints;
  final NavigationSimulationController? simulation;
  final MapDisplayMode mode;
  final TileProvider? tileProvider;
  final Offset riderOffset;
  const MakassarMapView({
    required this.route,
    this.gps,
    this.waypoints,
    this.simulation,
    this.mode = MapDisplayMode.preview,
    this.tileProvider,
    this.riderOffset = Offset.zero,
    super.key,
  });
  @override
  State<MakassarMapView> createState() => _MakassarMapViewState();
}

class _MakassarMapViewState extends State<MakassarMapView> {
  final controller = MapController();
  bool following = true, ready = false, tileFailed = false;
  bool gpsFocused = false;
  RoadRoute get displayedRoute {
    final gps = widget.gps;
    if (gps?.leg == null ||
        gps!.legIndex < 0 ||
        gps.legIndex >= widget.route.legs.length) {
      return widget.route;
    }
    return RoadRoute([
      for (var i = 0; i < widget.route.legs.length; i++)
        i == gps.legIndex ? gps.leg! : widget.route.legs[i],
    ]);
  }

  TileProvider? provider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??=
        widget.tileProvider ??
        MapTileScope.of(context)?.create() ??
        NetworkTileProvider();
  }

  LatLng get rider =>
      widget.gps?.fix?.point ??
      widget.simulation?.position ??
      widget.route.legs.first.points.first;
  @override
  void initState() {
    super.initState();
    widget.simulation?.addListener(moveRider);
    widget.gps?.addListener(moveRider);
  }

  @override
  void didUpdateWidget(covariant MakassarMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riderOffset != widget.riderOffset && following) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) moveRider();
      });
    }
    if (oldWidget.simulation != widget.simulation) {
      oldWidget.simulation?.removeListener(moveRider);
      widget.simulation?.addListener(moveRider);
      following = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) moveRider();
      });
    }
    if (oldWidget.gps != widget.gps) {
      oldWidget.gps?.removeListener(moveRider);
      widget.gps?.addListener(moveRider);
      gpsFocused = false;
      following = true;
      if (widget.gps != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ready) {
            fitRoute();
            moveRider();
          }
        });
      }
    }
  }

  void moveRider() {
    if (ready && following && (widget.gps == null || widget.gps!.reliable)) {
      controller.move(
        rider,
        widget.gps != null && !gpsFocused ? 16 : controller.camera.zoom,
        offset: widget.riderOffset,
      );
      if (widget.gps != null) gpsFocused = true;
    }
    setState(() {});
  }

  void recenter() {
    setState(() => following = true);
    if (widget.mode == MapDisplayMode.preview ||
        (widget.gps != null && !widget.gps!.reliable)) {
      fitRoute();
    } else {
      controller.move(
        rider,
        widget.gps != null && !gpsFocused ? 16 : controller.camera.zoom,
        offset: widget.riderOffset,
      );
      if (widget.gps != null) gpsFocused = true;
    }
  }

  @override
  void dispose() {
    widget.simulation?.removeListener(moveRider);
    widget.gps?.removeListener(moveRider);
    controller.dispose();
    super.dispose();
  }

  void fitRoute() {
    controller.fitCamera(
      CameraFit.coordinates(
        coordinates: displayedRoute.legs.expand((l) => l.points).toList(),
        padding: const EdgeInsets.fromLTRB(35, 35, 85, 70),
      ),
    );
  }

  void overview() {
    setState(() {
      following = false;
      gpsFocused = false;
    });
    fitRoute();
  }

  @override
  Widget build(BuildContext context) =>
      useGoogleMaps &&
          widget.tileProvider == null &&
          MapTileScope.of(context) == null
      ? GoogleRouteView(
          route: widget.route,
          gps: widget.gps,
          simulation: widget.simulation,
          waypoints: widget.waypoints,
          navigation: widget.mode == MapDisplayMode.navigation,
          riderOffset: widget.riderOffset,
        )
      : Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: rider,
                initialZoom: widget.mode == MapDisplayMode.navigation
                    ? 16
                    : 11.6,
                initialCameraFit:
                    widget.mode == MapDisplayMode.preview || widget.gps != null
                    ? CameraFit.coordinates(
                        coordinates: widget.route.legs
                            .expand((leg) => leg.points)
                            .toList(),
                        padding: const EdgeInsets.fromLTRB(35, 120, 75, 70),
                      )
                    : null,
                minZoom: 5,
                maxZoom: 19,
                backgroundColor: const Color(0xFFE2E8F0),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onMapReady: () {
                  ready = true;
                  if (widget.gps != null) {
                    fitRoute();
                    moveRider();
                  } else if (widget.mode == MapDisplayMode.navigation) {
                    recenter();
                  }
                },
                onPositionChanged: (_, gesture) {
                  if (gesture && following) setState(() => following = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.browcyl.kurir_go',
                  tileProvider: provider,
                  maxNativeZoom: 19,
                  errorTileCallback: (_, _, _) {
                    if (!mounted || tileFailed) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !tileFailed) {
                        setState(() => tileFailed = true);
                      }
                    });
                  },
                ),
                ...roadMapLayers(
                  displayedRoute,
                  widget.simulation,
                  widget.waypoints,
                  widget.gps,
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 64,
              child: MapControls(
                controller: controller,
                following: following,
                recenter: recenter,
                overview: overview,
              ),
            ),
            if (tileFailed)
              Positioned(
                left: 8,
                bottom: 56,
                right: 76,
                child: Material(
                  color: const Color(0xFF18181B),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'Peta dasar tidak tersedia. Rute tersimpan tetap aktif.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MapAttribution(),
            ),
          ],
        );
}
