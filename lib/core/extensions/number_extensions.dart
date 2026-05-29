import 'package:intl/intl.dart';

extension IntFormatExtension on int {
  /// 원화 포맷 (예: 350,000,000 → "3억 5,000만원", 1,950,500 → "195만 500원")
  String toKoreanWon() {
    if (this >= 100000000) {
      final eok = this ~/ 100000000;
      final remainder = this % 100000000;
      if (remainder == 0) return '${eok}억원';
      final man = remainder ~/ 10000;
      final won = remainder % 10000;
      if (won == 0) {
        return '${eok}억 ${NumberFormat('#,###').format(man)}만원';
      }
      if (man == 0) {
        return '${eok}억 ${NumberFormat('#,###').format(won)}원';
      }
      return '${eok}억 ${NumberFormat('#,###').format(man)}만 ${NumberFormat('#,###').format(won)}원';
    } else if (this >= 10000) {
      final man = this ~/ 10000;
      final won = this % 10000;
      if (won == 0) {
        return '${NumberFormat('#,###').format(man)}만원';
      }
      return '${NumberFormat('#,###').format(man)}만 ${NumberFormat('#,###').format(won)}원';
    }
    return '${NumberFormat('#,###').format(this)}원';
  }

  /// 콤마 포맷 (예: 1000000 → "1,000,000")
  String toCommaFormat() => NumberFormat('#,###').format(this);

  /// 원 단위 콤마 포맷 (예: 1000000 → "1,000,000원")
  String toWonFormat() => '${NumberFormat('#,###').format(this)}원';
}

extension DoubleFormatExtension on double {
  /// 퍼센트 포맷 (예: 0.035 → "3.50%")
  String toPercentFormat({int decimal = 2}) {
    return '${(this * 100).toStringAsFixed(decimal)}%';
  }
}
