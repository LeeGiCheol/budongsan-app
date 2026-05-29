/// 부동산 관련 금융 상수
class FinancialConstants {
  FinancialConstants._();

  // 취득가액 기준 금액
  static const int acquisitionPriceThresholdLow = 600000000;  // 6억
  static const int acquisitionPriceThresholdHigh = 900000000; // 9억

  // 취득세율 - 1주택자
  static const double acqTaxRate1H_under6 = 0.01;  // 6억 이하: 1%
  static const double acqTaxRate1H_over9 = 0.03;   // 9억 초과: 3%
  // 6억~9억: (취득가액 × 2/3억원 - 3) × 1/100

  // 취득세율 - 2주택자
  static const double acqTaxRate2H_regulated = 0.08;    // 조정대상: 8%
  // 비규제: 1주택자와 동일

  // 취득세율 - 3주택자
  static const double acqTaxRate3H_regulated = 0.12;    // 조정대상: 12%
  static const double acqTaxRate3H_nonRegulated = 0.08; // 비규제: 8%

  // 취득세율 - 4주택 이상
  static const double acqTaxRate4H = 0.12; // 12%

  // 농어촌특별세율 (전용면적 85㎡ 초과 시에만 적용)
  static const double ruralTax_02 = 0.002;  // 0.2%
  static const double ruralTax_06 = 0.006;  // 0.6%
  static const double ruralTax_10 = 0.01;   // 1%

  // 지방교육세율
  static const double localEduTax_01 = 0.001; // 0.1%
  static const double localEduTax_03 = 0.003; // 0.3%
  static const double localEduTax_04 = 0.004; // 0.4%
  // 6억~9억 구간: 취득세의 1/10

  // DSR 기준
  static const double dsrLimit = 0.40; // 40% DSR 규제

  // 기본값
  static const int defaultLoanTermYears = 30;
  static const double defaultInterestRate = 0.035; // 3.5%
  static const int monthsPerYear = 12;
}
