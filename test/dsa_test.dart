import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/dsa/adjacency_matrix.dart';
import 'package:kurir_go/core/dsa/cargo_stack.dart';
import 'package:kurir_go/core/dsa/graph.dart';
import 'package:kurir_go/core/dsa/priority_queue.dart';

void main() {
  test('Stack kosong dan operasi underflow', () {
    final stack = CargoStack<String>();
    expect(stack.isEmpty, isTrue);
    expect(stack.length, 0);
    expect(stack.pop, throwsStateError);
    expect(stack.peek, throwsStateError);
  });
  test('Loading terbalik menempatkan Antang di top; snapshot independen', () {
    final stack = CargoStack<String>()
      ..push('Sudiang')
      ..push('Antang');
    final snapshot = stack.toList();
    expect(stack.peek(), 'Antang');
    expect(stack.length, 2);
    expect(snapshot, ['Sudiang', 'Antang']);
    expect(() => snapshot.add('Depot'), throwsUnsupportedError);
    expect(stack.pop(), 'Antang');
    expect(stack.pop(), 'Sudiang');
    expect(stack.isEmpty, isTrue);
    stack.push('Depot');
    stack.clear();
    expect(stack.length, 0);
    expect(snapshot, ['Sudiang', 'Antang']);
  });
  test('Matrix diagonal nol, infinity, lookup dan arah independen', () {
    final matrix = AdjacencyMatrix(3);
    expect(matrix.size, 3);
    for (var u = 0; u < 3; u++) {
      for (var v = 0; v < 3; v++) {
        expect(matrix.getDistance(u, v), u == v ? 0.0 : double.infinity);
      }
    }
    matrix.setDistance(0, 2, 8.2);
    expect(matrix.getDistance(0, 2), 8.2);
    expect(matrix.getDistance(2, 0), double.infinity);
    expect(matrix.getDistance(1, 2), double.infinity);
    expect(matrix.rawMatrix[0][2], 8.2);
    matrix.setDistance(0, 2, 9.0);
    expect(matrix.getDistance(0, 2), 9.0);
    expect(() => matrix.getDistance(-1, 0), throwsRangeError);
    expect(() => matrix.setDistance(0, 3, 1), throwsRangeError);
    expect(AdjacencyMatrix(0).rawMatrix, isEmpty);
  });
  test('printMatrix menampilkan label dan bobot tanpa mengubah data', () {
    final lines = <String>[];
    final matrix = AdjacencyMatrix(2)..setDistance(0, 1, 8.2);
    runZoned(
      matrix.printMatrix,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    expect(lines.map((line) => line.split('|').map((s) => s.trim()).toList()), [
      ['', 'V0', 'V1'],
      ['V0', '0.0', '8.2'],
      ['V1', 'INF', '0.0'],
    ]);
    expect(matrix.getDistance(0, 1), 8.2);
  });
  test('Heap kosong, satu elemen dan penggunaan ulang', () {
    final heap = MinHeap<String>();
    expect(heap.isEmpty, isTrue);
    expect(heap.peek, throwsStateError);
    expect(heap.extractMin, throwsStateError);
    heap.insert('Antang', 8.2);
    expect(heap.peek(), 'Antang');
    expect(heap.length, 1);
    expect(heap.extractMin(), 'Antang');
    expect(heap.length, 0);
    heap.insert('Sudiang', 12.3);
    expect(heap.extractMin(), 'Sudiang');
    expect(() => heap.insert('Invalid', double.nan), throwsArgumentError);
    expect(heap.isEmpty, isTrue);
  });
  test('Heap mengurutkan input naik, terbalik dan acak deterministik', () {
    final expected = List.generate(100, (i) => i - 50);
    final random = [...expected]..shuffle(Random(42));
    for (final input in [expected, expected.reversed, random]) {
      final heap = MinHeap<int>();
      for (final value in input) {
        heap.insert(value, value.toDouble());
      }
      expect(List.generate(100, (_) => heap.extractMin()), expected);
      expect(heap.isEmpty, isTrue);
    }
  });
  test('Heap prioritas sama dan insert setelah extract', () {
    final heap = MinHeap<String>()
      ..insert('A', 2)
      ..insert('B', 2);
    heap.insert('C', 1);
    expect(heap.extractMin(), 'C');
    heap.insert('D', 0);
    expect(heap.extractMin(), 'D');
    expect([heap.extractMin(), heap.extractMin()], unorderedEquals(['A', 'B']));
  });
  const nodes = [
    GraphNode(id: 0, name: 'Pettarani'),
    GraphNode(id: 1, name: 'Sudiang'),
    GraphNode(id: 2, name: 'Antang'),
  ];
  const edge = DirectedEdge(
    from: 0,
    to: 2,
    distanceKm: 8.2,
    durationMinutes: 15,
  );
  test('Graf mempertahankan atribut, arah dan snapshot koleksi', () {
    final source = [...nodes];
    final sourceEdges = [edge];
    final graph = DeliveryGraph(nodes: source, edges: sourceEdges);
    source.clear();
    sourceEdges.clear();
    expect(graph.nodes.map((node) => node.name), [
      'Pettarani',
      'Sudiang',
      'Antang',
    ]);
    expect(graph.outgoingEdges(0).single.distanceKm, 8.2);
    expect(graph.outgoingEdges(0).single.durationMinutes, 15);
    expect(graph.outgoingEdges(2), isEmpty);
    expect(() => graph.nodes.clear(), throwsUnsupportedError);
    expect(() => graph.edges.clear(), throwsUnsupportedError);
  });
  test('Graf menolak ID duplikat dan endpoint yang tidak terdaftar', () {
    expect(
      () => DeliveryGraph(nodes: [nodes[0], nodes[0]], edges: []),
      throwsArgumentError,
    );
    expect(
      () => DeliveryGraph(nodes: [nodes[0]], edges: [edge]),
      throwsArgumentError,
    );
    expect(DeliveryGraph(nodes: [], edges: []).nodes, isEmpty);
  });
}
