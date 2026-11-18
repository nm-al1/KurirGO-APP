/// Bagasi dimuat terbalik: tujuan pertama berada di top (elemen terakhir).
class CargoStack<T> {
  final List<T> _storage = [];

  // Penambahan pada List dinamis membutuhkan O(1) amortized.
  void push(T item) => _storage.add(item);

  T pop() {
    if (isEmpty) throw StateError('Stack is empty');
    return _storage.removeLast();
  }

  T peek() {
    if (isEmpty) throw StateError('Stack is empty');
    return _storage.last;
  }

  bool get isEmpty => _storage.isEmpty;
  int get length => _storage.length;

  /// Snapshot dari dasar ke atas, tanpa mengekspos penyimpanan internal.
  List<T> toList() => List.unmodifiable(_storage);

  void clear() => _storage.clear();
}
