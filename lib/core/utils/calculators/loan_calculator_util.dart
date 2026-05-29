import 'dart:math';
import '../../constants/financial_constants.dart';

/// 대출 상환 방식
enum RepaymentType {
  /// 원리금균등상환
  equalPrincipalAndInterest,

  /// 원금균등상환
  equalPrincipal,

  /// 만기일시상환
  bulletRepayment,
}

/// 월별 상환 정보
class MonthlyPayment {
  final int month;
  final int principal; // 원금 상환액 (원)
  final int interest; // 이자 (원)
  final int totalPayment; // 월 상환액 (원)
  final int remainingBalance; // 잔여 원금 (원)

  const MonthlyPayment({
    required this.month,
    required this.principal,
    required this.interest,
    required this.totalPayment,
    required this.remainingBalance,
  });
}

/// 대출 계산 유틸리티
class LoanCalculatorUtil {
  LoanCalculatorUtil._();

  /// 원리금균등상환 월 상환액 계산
  /// [principal] 대출 원금 (원)
  /// [annualRate] 연 이율 (예: 0.035 = 3.5%)
  /// [termMonths] 상환 기간 (월)
  static int calculateEqualPayment({
    required int principal,
    required double annualRate,
    required int termMonths,
  }) {
    if (annualRate == 0) return (principal / termMonths).round();
    final monthlyRate = annualRate / FinancialConstants.monthsPerYear;
    final payment = principal *
        monthlyRate *
        pow(1 + monthlyRate, termMonths) /
        (pow(1 + monthlyRate, termMonths) - 1);
    return payment.round();
  }

  /// 원금균등상환 스케줄 생성
  static List<MonthlyPayment> generateEqualPrincipalSchedule({
    required int principal,
    required double annualRate,
    required int termMonths,
  }) {
    final monthlyPrincipal = (principal / termMonths).round();
    final monthlyRate = annualRate / FinancialConstants.monthsPerYear;
    final schedule = <MonthlyPayment>[];
    int remaining = principal;

    for (int i = 1; i <= termMonths; i++) {
      final interest = (remaining * monthlyRate).round();
      final total = monthlyPrincipal + interest;
      remaining -= monthlyPrincipal;
      if (remaining < 0) remaining = 0;

      schedule.add(MonthlyPayment(
        month: i,
        principal: monthlyPrincipal,
        interest: interest,
        totalPayment: total,
        remainingBalance: remaining,
      ));
    }
    return schedule;
  }

  /// 만기일시상환 월 이자 계산
  static int calculateBulletInterest({
    required int principal,
    required double annualRate,
  }) {
    final monthlyRate = annualRate / FinancialConstants.monthsPerYear;
    return (principal * monthlyRate).round();
  }

  /// 총 이자 계산
  static int calculateTotalInterest({
    required int principal,
    required double annualRate,
    required int termMonths,
    required RepaymentType type,
  }) {
    switch (type) {
      case RepaymentType.equalPrincipalAndInterest:
        final monthly = calculateEqualPayment(
          principal: principal,
          annualRate: annualRate,
          termMonths: termMonths,
        );
        return (monthly * termMonths) - principal;
      case RepaymentType.equalPrincipal:
        final schedule = generateEqualPrincipalSchedule(
          principal: principal,
          annualRate: annualRate,
          termMonths: termMonths,
        );
        return schedule.fold(0, (sum, p) => sum + p.interest);
      case RepaymentType.bulletRepayment:
        return calculateBulletInterest(
              principal: principal,
              annualRate: annualRate,
            ) *
            termMonths;
    }
  }
}
