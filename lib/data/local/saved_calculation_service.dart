import 'package:hive/hive.dart';
import '../models/saved_calculation.dart';

/// Hive 기반 저장된 계산 서비스
class SavedCalculationService {
  static const String _boxName = 'saved_calculations';

  Box? _box;

  Future<Box> get box async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  /// 저장
  Future<void> save(SavedCalculation item) async {
    final b = await box;
    await b.put(item.id, item.toMap());
  }

  /// 삭제
  Future<void> delete(String id) async {
    final b = await box;
    await b.delete(id);
  }

  /// 전체 조회 (최신순)
  Future<List<SavedCalculation>> getAll() async {
    final b = await box;
    final items = b.values
        .map((e) => SavedCalculation.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  /// ID로 존재 여부 확인
  Future<bool> exists(String id) async {
    final b = await box;
    return b.containsKey(id);
  }

  /// 전체 삭제
  Future<void> clear() async {
    final b = await box;
    await b.clear();
  }
}
