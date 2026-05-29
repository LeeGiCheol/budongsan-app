/// 부동산 관련 금융 상수
class FinancialConstants {
  FinancialConstants._();

  // 취득세율 (2024년 기준)
  static const double acquisitionTaxRate1House = 0.01; // 1주택 6억 이하
  static const double acquisitionTaxRate1HouseMid = 0.013; // 1주택 6~9억
  static const double acquisitionTaxRate1HouseHigh = 0.03; // 1주택 9억 초과
  static const double acquisitionTaxRate2House = 0.08; // 2주택 (조정대상)
  static const double acquisitionTaxRate3House = 0.12; // 3주택 이상

  // 부대비용
  static const double localEducationTaxRate = 0.001; // 지방교육세
  static const double specialRuralDevTaxRate = 0.002; // 농어촌특별세

  // DSR 기준
  static const double dsrLimit = 0.40; // 40% DSR 규제

  // 기본값
  static const int defaultLoanTermYears = 30;
  static const double defaultInterestRate = 0.035; // 3.5%
  static const int monthsPerYear = 12;
}
