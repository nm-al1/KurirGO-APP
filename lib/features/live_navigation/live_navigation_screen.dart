import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/models/road_route.dart';
import '../controllers/navigation_simulation_controller.dart';
import '../shared/delivery_scope.dart';
import '../shared/presentation.dart';
import 'customer_console.dart';
import 'navigation_stage.dart';

class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key});
  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Future<RoadRoute> route = RoadRoute.load();
  NavigationSimulationController? simulation;
  int activeLeg = -1;
  Duration previous = Duration.zero;
  late final Ticker ticker = createTicker((elapsed) {
    simulation?.advance(elapsed - previous);
    previous = elapsed;
    if (simulation?.running != true) ticker.stop();
  });
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ticker.stop();
      simulation?.pause();
    }
  }

  void toggle() {
    final s = simulation!;
    if (s.running) {
      ticker.stop();
      s.pause();
    } else {
      previous = Duration.zero;
      s.play();
      if (s.running) ticker.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    simulation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    final order = c.currentOrder;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<RoadRoute>(
          future: route,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(() => route = RoadRoute.load()),
                  child: const Text('Rute tidak dapat dimuat. Coba lagi'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final roads = snapshot.data!;
            final leg = c.currentStopIndex.clamp(0, 2);
            if (leg != activeLeg) {
              ticker.stop();
              simulation?.dispose();
              simulation = NavigationSimulationController(roads.legs[leg]);
              activeLeg = leg;
            }
            final s = simulation!;
            final point = c.waypoints[order?.waypointIndex ?? 0];
            return ListView(
              children: [
                NavigationStage(
                  roads: roads,
                  simulation: s,
                  destination: point,
                  title: order == null
                      ? 'Pulang ke Depot Pettarani'
                      : 'Stop #${leg + 1} - ${point.name}',
                  onToggle: toggle,
                  onReplay: () {
                    ticker.stop();
                    s.replay();
                  },
                ),
                if (order != null)
                  CustomerConsole(
                    order: order,
                    isLastStop: leg == 1,
                    onComplete: (payment) {
                      try {
                        ticker.stop();
                        s.pause();
                        c.completeCurrentStop(payment, orderId: order.id);
                        if (c.currentStopIndex == 2) {
                          replaceWith(context, '/history');
                        }
                      } catch (error) {
                        showProblem(context, error);
                      }
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ActionPill(
                      'Lihat Riwayat & Setor',
                      onPressed: () => replaceWith(context, '/history'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
