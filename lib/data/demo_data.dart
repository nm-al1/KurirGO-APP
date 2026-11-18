import 'courier_store.dart';

class DemoData {
  static const locations = [
    (-5.1685, 119.4820, 'Antang'),
    (-5.0782, 119.5215, 'Sudiang'),
    (-5.1477, 119.4327, 'Rappocini'),
    (-5.1610, 119.4190, 'Mamajang'),
    (-5.1400, 119.4150, 'Losari'),
  ];
  static Json seed(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    Json order(int i, DateTime date) {
      final location = locations[i % 5];
      return {
        'id': 'DEMO-${i.toString().padLeft(3, '0')}',
        'recipient': 'Penerima Contoh ${i + 1}',
        'phone': '08000000000',
        'address': 'Alamat contoh ${location.$3}, Makassar',
        'items': i.isEven ? 'Brownies cokelat' : 'Choco banana melt',
        'boxes': i % 4 + 1,
        'bill': (i % 4 + 1) * 75000,
        'lat': location.$1,
        'lng': location.$2,
        'status': 'waiting',
        'createdAt': date.toUtc().toIso8601String(),
      };
    }

    final orders = <Json>[for (var i = 0; i < 6; i++) order(i, day)];
    final trips = <Json>[];
    for (var d = 0; d < 7; d++) {
      final date = day.subtract(Duration(days: d));
      final trip = 'DEMO-TRIP-$d';
      final ids = <String>[];
      for (var j = 0; j < 2; j++) {
        final i = 6 + d * 2 + j, o = order(i, date);
        final method = ['cash', 'qris', 'transfer'][i % 3];
        o.addAll({
          'status': 'completed',
          'tripId': trip,
          'completedAt': date
              .add(Duration(hours: 10 + j))
              .toUtc()
              .toIso8601String(),
          'payment': {
            'method': method,
            'received': o['bill'] + (method == 'cash' && j == 0 ? 50000 : 0),
            'reference': method == 'cash' ? '' : 'DEMO-PAY-$i',
          },
        });
        orders.add(o);
        ids.add(o['id']);
      }
      trips.add({
        'id': trip,
        'startedAt': date
            .add(const Duration(hours: 9))
            .toUtc()
            .toIso8601String(),
        'settledAt': date
            .add(const Duration(hours: 12))
            .toUtc()
            .toIso8601String(),
        'stops': [
          for (final id in ids) [id],
        ],
        'distance': 12000,
        'duration': 3600,
      });
    }
    return {
      'orders': orders,
      'trips': trips,
      'demoSeededAt': now.toIso8601String(),
    };
  }
}
