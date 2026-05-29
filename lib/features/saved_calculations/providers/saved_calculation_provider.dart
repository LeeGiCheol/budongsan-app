import 'package:flutter/foundation.dart';
import '../../../data/local/saved_calculation_service.dart';
import '../../../data/models/saved_calculation.dart';

class SavedCalculationProvider extends ChangeNotifier {
  final SavedCalculationService _service;
  List<SavedCalculation> _items = [];
  final Set<String> _savedIds = {};

  SavedCalculationProvider({SavedCalculationService? service})
      : _service = service ?? SavedCalculationService();

  List<SavedCalculation> get items => List.unmodifiable(_items);
  Set<String> get savedIds => Set.unmodifiable(_savedIds);

  /// 초기 로드
  Future<void> load() async {
    _items = await _service.getAll();
    _savedIds.clear();
    for (final item in _items) {
      _savedIds.add(item.id);
    }
    notifyListeners();
  }

  /// 저장 여부 확인
  bool isSaved(String id) => _savedIds.contains(id);

  /// 저장 토글 (저장 ↔ 삭제)
  Future<void> toggle(SavedCalculation item) async {
    if (_savedIds.contains(item.id)) {
      await _service.delete(item.id);
      _savedIds.remove(item.id);
      _items.removeWhere((e) => e.id == item.id);
    } else {
      await _service.save(item);
      _savedIds.add(item.id);
      _items.insert(0, item);
    }
    notifyListeners();
  }

  /// 삭제
  Future<void> remove(String id) async {
    await _service.delete(id);
    _savedIds.remove(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// 전체 삭제
  Future<void> clearAll() async {
    await _service.clear();
    _savedIds.clear();
    _items.clear();
    notifyListeners();
  }
}
