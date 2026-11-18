import '../core/dsa/adjacency_matrix.dart';
import 'models/order_model.dart';
import 'models/payment_model.dart';
import 'models/waypoint_model.dart';

/// Fixture proyek yang disepakati; jarak belum diverifikasi pengukuran jalan.
class DummyMakassarData {
  static const waypoints = [
    WaypointModel(
      id: 'V0',
      name: 'Hub Depot Pettarani',
      nodeIndex: 0,
      address: 'Jl. A.P. Pettarani No. 10',
      latitude: -5.1560,
      longitude: 119.4350,
    ),
    WaypointModel(
      id: 'V1',
      name: 'Outlet Sudiang',
      nodeIndex: 1,
      address: 'Jl. Perintis Kemerdekaan KM 18 No. 88, Sudiang, Makassar',
      latitude: -5.0782,
      longitude: 119.5215,
    ),
    WaypointModel(
      id: 'V2',
      name: 'Outlet Antang',
      nodeIndex: 2,
      address: 'Jl. Antang Raya No. 45, Antang, Makassar',
      latitude: -5.1685,
      longitude: 119.4820,
    ),
  ];

  static AdjacencyMatrix createDistanceMatrix() {
    const distances = [
      [0.0, 16.5, 8.2],
      [8.0, 0.0, 12.3],
      [8.2, 12.3, 0.0],
    ];
    final matrix = AdjacencyMatrix(waypoints.length);
    for (var u = 0; u < matrix.size; u++) {
      for (var v = 0; v < matrix.size; v++) {
        matrix.setDistance(u, v, distances[u][v]);
      }
    }
    return matrix;
  }

  static List<OrderModel> createOrders() => [
    OrderModel(
      id: 'BRW-01',
      customerName: 'Bpk. Rahmat (Outlet Sudiang)',
      customerPhone: '0811-4455-6677',
      waypointIndex: 1,
      boxCount: 3,
      itemsDescription: '3 Box (Unti Kelapa & Brownies Cokelat)',
      totalPrice: 225000,
      payment: PaymentDetail(
        nominalTagihan: 225000,
        metode: PaymentMethod.qris,
        status: PaymentStatus.paid,
      ),
    ),
    OrderModel(
      id: 'BRW-02',
      customerName: 'Ibu Nurul (Outlet Antang)',
      customerPhone: '0812-9988-7766',
      waypointIndex: 2,
      boxCount: 2,
      itemsDescription: '2 Box (Choco Banana Melt)',
      totalPrice: 150000,
      payment: PaymentDetail(nominalTagihan: 150000, metode: PaymentMethod.cod),
    ),
  ];
}
