import 'package:flutter/material.dart';

import '../../data/models/road_route.dart';
import '../../data/models/waypoint_model.dart';
import '../controllers/navigation_simulation_controller.dart';
import '../shared/external_actions.dart';
import '../shared/makassar_map_view.dart';
import 'navigation_hud.dart';

class NavigationStage extends StatelessWidget {
  final RoadRoute roads;
  final NavigationSimulationController simulation;
  final WaypointModel destination;
  final String title;
  final VoidCallback onToggle, onReplay;
  const NavigationStage({
    required this.roads,
    required this.simulation,
    required this.destination,
    required this.title,
    required this.onToggle,
    required this.onReplay,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) => MakassarMapView(
            route: roads,
            simulation: simulation,
            mode: MapDisplayMode.navigation,
            riderOffset: Offset(0, (constraints.maxHeight - 300) / 2),
          ),
        ),
      ),
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListenableBuilder(
              listenable: simulation,
              builder: (context, _) => NavigationHud(
                simulation: simulation,
                destination: title,
                onToggle: onToggle,
                onReplay: onReplay,
                onMaps: () => launchCourierLink(
                  context,
                  mapsUri(destination, origin: simulation.position),
                  destination.address,
                ),
              ),
            ),
          ),
          const SizedBox(height: 300),
        ],
      ),
    ],
  );
}
