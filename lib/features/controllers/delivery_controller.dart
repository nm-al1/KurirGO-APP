import 'package:flutter/foundation.dart';

import '../../core/algorithms/held_karp_tsp.dart';
import '../../core/algorithms/nearest_neighbor_tsp.dart';
import '../../core/algorithms/tsp_solver.dart';
import '../../core/dsa/cargo_stack.dart';
import '../../data/dummy_makassar_data.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_model.dart';
import 'courier_account.dart';
import 'payment_validation.dart';

class DeliveryController extends ChangeNotifier {
  final account = CourierAccount();
  final waypoints = DummyMakassarData.waypoints;
  final distanceMatrix = DummyMakassarData.createDistanceMatrix();
  List<OrderModel> orders = DummyMakassarData.createOrders();
  final cargoStack = CargoStack<OrderModel>();
  final List<OrderModel> _completed = [];
  TSPResult? activeTourResult;
  TSPResult? comparisonResult;
  int currentStopIndex = 0;
  bool isNavigating = false;
  bool isSettled = false;

  DeliveryController() {
    _loadCargo([0, 2, 1, 0]);
  }

  String get username => account.username;
  bool get loggedIn => account.loggedIn;
  List<OrderModel> get completedOrders => List.unmodifiable(_completed);
  bool get isAllOrdersVerified =>
      orders.isNotEmpty && orders.every((o) => o.isVerified);
  OrderModel? get currentOrder => cargoStack.isEmpty ? null : cargoStack.peek();
  int get boxesDelivered => _completed.fold(0, (sum, o) => sum + o.boxCount);
  int get totalBoxes => orders.fold(0, (sum, o) => sum + o.boxCount);
  double get cashToDeposit => _total(true);
  double get nonCashTotal => _total(false);
  double get revenue => cashToDeposit + nonCashTotal;

  double _total(bool cash) => _completed
      .where(
        (o) =>
            (o.payment.metode == PaymentMethod.cod ||
                o.payment.metode == PaymentMethod.cash) ==
            cash,
      )
      .fold(0.0, (sum, o) => sum + o.payment.nominalTagihan);

  void login(String username, String pin) {
    account.login(username, pin);
    notifyListeners();
  }

  void updateProfile(String name, String phone) {
    account.updateProfile(name, phone);
    notifyListeners();
  }

  void register({
    required String name,
    required String username,
    required String pin,
    String? whatsapp,
  }) {
    account.register(
      name: name,
      username: username,
      pin: pin,
      whatsapp: whatsapp,
    );
    notifyListeners();
  }

  void toggleOrderVerification(String orderId) {
    if (isNavigating || isSettled) throw StateError('Rute sudah berjalan.');
    final order = orders.firstWhere((o) => o.id == orderId);
    order.isVerified = !order.isVerified;
    activeTourResult = null;
    comparisonResult = null;
    _loadCargo([0, 2, 1, 0]);
    notifyListeners();
  }

  void _loadCargo(List<int> tour) {
    cargoStack.clear();
    for (final node in tour.sublist(1, tour.length - 1).reversed) {
      for (final order in orders.where((o) => o.waypointIndex == node)) {
        cargoStack.push(order);
      }
    }
  }

  void calculateOptimalRoute({bool useHeldKarp = true}) {
    if (!isAllOrdersVerified || isNavigating || isSettled) {
      throw StateError('Verifikasi semua pesanan sebelum mengurutkan rute.');
    }
    final exact = HeldKarpTSP().solve(distanceMatrix, 0);
    final greedy = NearestNeighborTSP().solve(distanceMatrix, 0);
    activeTourResult = useHeldKarp ? exact : greedy;
    comparisonResult = useHeldKarp ? greedy : exact;
    _loadCargo(activeTourResult!.tour);
    notifyListeners();
  }

  void startNavigation() {
    if (activeTourResult == null || !isAllOrdersVerified || isSettled) {
      throw StateError('Rute belum siap.');
    }
    isNavigating = true;
    notifyListeners();
  }

  void completeCurrentStop(PaymentDetail payment, {required String orderId}) {
    final order = currentOrder;
    if (!isNavigating || order == null || order.id != orderId || isSettled) {
      throw StateError('Pesanan ini bukan tujuan aktif.');
    }
    validateDeliveryPayment(order, payment);
    order.payment = payment;
    _completed.add(cargoStack.pop());
    currentStopIndex++;
    notifyListeners();
  }

  void settleAtDepot() {
    if (currentStopIndex != 2 || !cargoStack.isEmpty || isSettled) {
      throw StateError('Selesaikan kedua pengantaran sebelum setor.');
    }
    isSettled = true;
    isNavigating = false;
    notifyListeners();
  }

  void startNewRoute() {
    if (isNavigating && !isSettled) {
      throw StateError('Selesaikan rute aktif dahulu.');
    }
    orders = DummyMakassarData.createOrders();
    _completed.clear();
    activeTourResult = null;
    comparisonResult = null;
    currentStopIndex = 0;
    isSettled = false;
    isNavigating = false;
    _loadCargo([0, 2, 1, 0]);
    notifyListeners();
  }
}
