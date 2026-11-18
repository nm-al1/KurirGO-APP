import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/data/models/payment_model.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';
import 'package:kurir_go/core/algorithms/held_karp_tsp.dart';

void main() {
  test('Cash/COD: lebih, pas, kurang dan belum diterima', () {
    for (final method in [PaymentMethod.cash, PaymentMethod.cod]) {
      for (final received in <double?>[200000, 150000, 100000, null]) {
        final payment = PaymentDetail(
          nominalTagihan: 150000,
          metode: method,
          nominalDiterima: received,
        );
        expect(payment.uangKembalian, received == 200000 ? 50000 : 0);
        expect(payment.status, PaymentStatus.pending);
      }
    }
  });
  test('QRIS/Transfer tidak memberikan kembalian tunai', () {
    for (final method in [PaymentMethod.qris, PaymentMethod.transfer]) {
      final payment = PaymentDetail(
        nominalTagihan: 150000,
        metode: method,
        nominalDiterima: 200000,
        referensiTransaksi: 'TEST-01',
      );
      expect(payment.uangKembalian, 0);
      expect(payment.referensiTransaksi, 'TEST-01');
      payment.status = PaymentStatus.verified;
      expect(payment.status, PaymentStatus.verified);
    }
  });
  test('Nominal negatif/nonfinite ditolak', () {
    for (final value in [
      -1.0,
      double.infinity,
      double.negativeInfinity,
      double.nan,
    ]) {
      expect(
        () => PaymentDetail(nominalTagihan: value, metode: PaymentMethod.cash),
        throwsArgumentError,
      );
      expect(
        () => PaymentDetail(
          nominalTagihan: 0,
          nominalDiterima: value,
          metode: PaymentMethod.cod,
        ),
        throwsArgumentError,
      );
    }
  });
  test('Waypoint dan matriks fixture konsisten; loop optimal 28.5 km', () {
    final points = DummyMakassarData.waypoints;
    expect(points.map((p) => p.id), ['V0', 'V1', 'V2']);
    expect(points.map((p) => p.nodeIndex), [0, 1, 2]);
    expect(points.map((p) => p.isDepot), [true, false, false]);
    expect(points.map((p) => (p.latitude, p.longitude)), [
      (-5.1560, 119.4350),
      (-5.0782, 119.5215),
      (-5.1685, 119.4820),
    ]);
    expect(
      points[1].address,
      'Jl. Perintis Kemerdekaan KM 18 No. 88, Sudiang, Makassar',
    );
    expect(points[2].address, 'Jl. Antang Raya No. 45, Antang, Makassar');
    expect(() => points.clear(), throwsUnsupportedError);
    final matrix = DummyMakassarData.createDistanceMatrix();
    expect(matrix.rawMatrix, [
      [0, 16.5, 8.2],
      [8, 0, 12.3],
      [8.2, 12.3, 0],
    ]);
    final result = HeldKarpTSP().solve(matrix, 0);
    expect(result.tour, [0, 2, 1, 0]);
    expect(result.totalDistance, closeTo(28.5, 1e-9));
  });
  test('Manifest 5 box dengan pembayaran terpisah dari verifikasi bagasi', () {
    final orders = DummyMakassarData.createOrders();
    expect(orders.map((o) => o.id), ['BRW-01', 'BRW-02']);
    expect(orders.map((o) => o.customerName), [
      'Bpk. Rahmat (Outlet Sudiang)',
      'Ibu Nurul (Outlet Antang)',
    ]);
    expect(orders.map((o) => o.customerPhone), [
      '0811-4455-6677',
      '0812-9988-7766',
    ]);
    expect(orders.map((o) => o.waypointIndex), [1, 2]);
    expect(orders.map((o) => o.boxCount), [3, 2]);
    expect(orders.map((o) => o.itemsDescription), [
      '3 Box (Unti Kelapa & Brownies Cokelat)',
      '2 Box (Choco Banana Melt)',
    ]);
    expect(orders.map((o) => o.totalPrice), [225000, 150000]);
    expect(orders.map((o) => o.payment.metode), [
      PaymentMethod.qris,
      PaymentMethod.cod,
    ]);
    expect(orders.map((o) => o.payment.status), [
      PaymentStatus.paid,
      PaymentStatus.pending,
    ]);
    for (final order in orders) {
      expect(order.isVerified, isFalse);
      expect(order.payment.nominalTagihan, order.totalPrice);
      expect(order.payment.nominalDiterima, isNull);
      expect(order.payment.referensiTransaksi, isNull);
    }
  });
  test('Objek matrix, pesanan dan pembayaran tidak bocor antar-shift', () {
    final first = DummyMakassarData.createOrders();
    first.first.isVerified = true;
    first.first.payment.status = PaymentStatus.verified;
    first.last.payment = PaymentDetail(
      nominalTagihan: 150000,
      nominalDiterima: 200000,
      metode: PaymentMethod.cash,
    );
    final fresh = DummyMakassarData.createOrders();
    expect(fresh.first.isVerified, isFalse);
    expect(fresh.first.payment.status, PaymentStatus.paid);
    expect(fresh.last.payment.metode, PaymentMethod.cod);
    final matrix = DummyMakassarData.createDistanceMatrix()
      ..setDistance(1, 0, 99);
    expect(matrix.getDistance(1, 0), 99);
    expect(DummyMakassarData.createDistanceMatrix().getDistance(1, 0), 8);
  });
}
