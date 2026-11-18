class AdjacencyMatrix {
  final int size;
  final List<List<double>> _matrix;

  AdjacencyMatrix(this.size)
    : _matrix = List.generate(size, (_) => List.filled(size, double.infinity)) {
    for (var i = 0; i < size; i++) {
      _matrix[i][i] = 0.0;
    }
  }

  void setDistance(int u, int v, double dist) => _matrix[u][v] = dist;
  double getDistance(int u, int v) => _matrix[u][v];

  List<List<double>> get rawMatrix => _matrix;

  void printMatrix() {
    final labels = List.generate(size, (i) => 'V$i');
    final rows = <List<String>>[
      ['', ...labels],
      for (var i = 0; i < size; i++)
        [labels[i], ..._matrix[i].map((d) => d.isInfinite ? 'INF' : '$d')],
    ];
    final width = rows
        .expand((row) => row)
        .fold<int>(
          3,
          (width, cell) => cell.length > width ? cell.length : width,
        );
    for (final row in rows) {
      // ignore: avoid_print -- Visualisasi console merupakan kontrak helper ini.
      // ignore: avoid_print
      print(row.map((cell) => cell.padLeft(width)).join(' | '));
    }
  }
}
