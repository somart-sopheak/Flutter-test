import 'dart:async';
import 'dart:ui';

class Debounce {
  Timer? _timer;

  void run(VoidCallback action, {Duration delay = const Duration(milliseconds: 500)}) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
