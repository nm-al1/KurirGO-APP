import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/controllers/delivery_controller.dart';
import 'package:kurir_go/data/models/payment_model.dart';

void verifyAndStart(DeliveryController c) {
  c.toggleOrderVerification('BRW-01');
  c.toggleOrderVerification('BRW-02');
  c.calculateOptimalRoute();
  c.startNavigation();
}

PaymentDetail paid(PaymentMethod method, {double received = 200000}) =>
    PaymentDetail(
      nominalTagihan: 150000,
      metode: method,
      nominalDiterima: received,
      status: PaymentStatus.paid,
    );

void main() {
  late DeliveryController c;
  setUp(() => c = DeliveryController());
  tearDown(() => c.dispose());
  test('Auth demo, validasi dan akun lokal baru', () {
    expect(c.loggedIn, isFalse);
    expect(() => c.login('ardiansyah', '9999'), throwsArgumentError);
    c.login('ardiansyah', '1234');
    expect(c.loggedIn, isTrue);
    c.register(name: 'Rahmat', username: 'rahmat', pin: '5678');
    expect(c.account.fullName, 'Rahmat');
    expect(c.account.isAvailable('rahmat'), isFalse);
    expect(
      () => c.register(name: 'X', username: 'rahmat', pin: '1234'),
      throwsArgumentError,
    );
    expect(
      () => c.register(name: '', username: 'new', pin: '1'),
      throwsArgumentError,
    );
    expect(
      () =>
          c.register(name: 'X', username: 'new', pin: '1234', whatsapp: 'bad'),
      throwsArgumentError,
    );
    c.login('ardiansyah', '1234');
    expect(c.username, 'ardiansyah');
  });
  test('LIFO dan gate verifikasi, solver dan notifikasi', () {
    var changes = 0;
    c.addListener(() => changes++);
    expect(c.cargoStack.peek().id, 'BRW-02');
    expect(c.cargoStack.toList().map((o) => o.id), ['BRW-01', 'BRW-02']);
    expect(() => c.calculateOptimalRoute(), throwsStateError);
    expect(() => c.startNavigation(), throwsStateError);
    c.toggleOrderVerification('BRW-02');
    expect(c.cargoStack.length, 2);
    c.toggleOrderVerification('BRW-01');
    c.calculateOptimalRoute();
    expect(c.activeTourResult!.tour, [0, 2, 1, 0]);
    expect(c.activeTourResult!.totalDistance, closeTo(28.5, 1e-9));
    c.calculateOptimalRoute(useHeldKarp: false);
    expect(c.activeTourResult!.algorithmName, 'Nearest Neighbor');
    c.toggleOrderVerification('BRW-01');
    expect(c.activeTourResult, isNull);
    expect(changes, 5);
  });
  test('Cash/COD memerlukan pembayaran cukup dan pesanan aktif', () {
    verifyAndStart(c);
    expect(() => c.toggleOrderVerification('BRW-01'), throwsStateError);
    expect(() => c.calculateOptimalRoute(), throwsStateError);
    expect(() => c.startNewRoute(), throwsStateError);
    expect(() => c.settleAtDepot(), throwsStateError);
    expect(
      () => c.completeCurrentStop(
        paid(PaymentMethod.cod, received: 100000),
        orderId: 'BRW-02',
      ),
      throwsArgumentError,
    );
    expect(
      () => c.completeCurrentStop(paid(PaymentMethod.cod), orderId: 'BRW-01'),
      throwsStateError,
    );
    c.completeCurrentStop(paid(PaymentMethod.cash), orderId: 'BRW-02');
    expect(c.completedOrders.single.payment.uangKembalian, 50000);
    expect(c.currentOrder!.id, 'BRW-01');
    expect(c.boxesDelivered, 2);
    expect(
      () => c.completeCurrentStop(paid(PaymentMethod.cod), orderId: 'BRW-02'),
      throwsStateError,
    );
  });
  test('Rekap, perjalanan pulang, setoran dan reset', () {
    c.login('ardiansyah', '1234');
    verifyAndStart(c);
    c.completeCurrentStop(paid(PaymentMethod.cod), orderId: 'BRW-02');
    c.completeCurrentStop(c.currentOrder!.payment, orderId: 'BRW-01');
    expect(c.currentStopIndex, 2);
    expect(c.currentOrder, isNull);
    expect(c.cashToDeposit, 150000);
    expect(c.nonCashTotal, 225000);
    expect(c.revenue, 375000);
    expect(c.boxesDelivered, 5);
    expect(c.isSettled, isFalse);
    c.settleAtDepot();
    expect(c.isSettled, isTrue);
    expect(() => c.settleAtDepot(), throwsStateError);
    expect(() => c.completedOrders.clear(), throwsUnsupportedError);
    c.startNewRoute();
    expect(c.isAllOrdersVerified, isFalse);
    expect(c.currentStopIndex, 0);
    expect(c.cashToDeposit, 0);
    expect(c.activeTourResult, isNull);
    expect(c.loggedIn, isTrue);
    expect(c.cargoStack.peek().id, 'BRW-02');
  });
  for (final method in [PaymentMethod.qris, PaymentMethod.transfer]) {
    test('Rekap mengikuti perubahan metode ${method.name}', () {
      verifyAndStart(c);
      c.completeCurrentStop(paid(method), orderId: 'BRW-02');
      expect(c.cashToDeposit, 0);
      expect(c.nonCashTotal, 150000);
    });
  }
  test('Pembayaran pending atau tagihan berbeda tidak menyelesaikan stop', () {
    verifyAndStart(c);
    expect(
      () => c.completeCurrentStop(
        PaymentDetail(nominalTagihan: 150000, metode: PaymentMethod.cod),
        orderId: 'BRW-02',
      ),
      throwsArgumentError,
    );
    expect(
      () => c.completeCurrentStop(
        PaymentDetail(
          nominalTagihan: 1,
          metode: PaymentMethod.qris,
          status: PaymentStatus.paid,
        ),
        orderId: 'BRW-02',
      ),
      throwsArgumentError,
    );
    expect(c.cargoStack.length, 2);
  });
}
