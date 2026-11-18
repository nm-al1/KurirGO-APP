class HeapNode<T> {
  final T data;
  final double priority;
  HeapNode(this.data, this.priority);
}

/// Binary min-heap: insert/extract O(log N), peek O(1).
class MinHeap<T> {
  final List<HeapNode<T>> _heap = [];

  int get length => _heap.length;
  bool get isEmpty => _heap.isEmpty;

  void insert(T element, double priority) {
    if (priority.isNaN) throw ArgumentError.value(priority, 'priority');
    _heap.add(HeapNode(element, priority));
    _bubbleUp(_heap.length - 1);
  }

  T peek() {
    if (isEmpty) throw StateError('Heap is empty');
    return _heap.first.data;
  }

  T extractMin() {
    if (isEmpty) throw StateError('Heap is empty');
    final min = _heap.first.data;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return min;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_heap[parent].priority <= _heap[index].priority) break;
      _swap(index, parent);
      index = parent;
    }
  }

  void _bubbleDown(int index) {
    while (2 * index + 1 < length) {
      var child = 2 * index + 1;
      final right = child + 1;
      if (right < length && _heap[right].priority < _heap[child].priority) {
        child = right;
      }
      if (_heap[index].priority <= _heap[child].priority) break;
      _swap(index, child);
      index = child;
    }
  }

  void _swap(int a, int b) {
    final temp = _heap[a];
    _heap[a] = _heap[b];
    _heap[b] = temp;
  }
}
