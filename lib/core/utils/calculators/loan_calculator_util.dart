import 'dart:math';

/// 대출 상환 방식
enum RepaymentType {
  /// 원리금균등상환
  equalPrincipalAndInterest,

  /// 원금균등상환
  equalPrincipal,

  /// 만기일시상환
  bulletRepayment,
}

/// 중도상환 정보
class Prepayment {
  final int month; // 몇 회차에 상환
  final int amount; // 상환 금액 (원)
  final double feeRate; // 중도상환 수수료율 (예: 0.012 = 1.2%)

  const Prepayment({
    required this.month,
    required this.amount,
    required this.feeRate,
  });

  int get fee => (amount * feeRate).round();
}

/// 월별 상환 정보
class MonthlyPayment {
  final int month;
  final int principal; // 원금 상환액 (원)
  final int interest; // 이자 (원)
  final int totalPayment; // 월 상환액 (원금+이자)
  final int remainingBalance; // 잔여 원금 (원)
  final int prepaymentAmount; // 중도상환 원금 (원)
  final int prepaymentFee; // 중도상환 수수료 (원)

  const MonthlyPayment({
    required this.month,
    required this.principal,
    required this.interest,
    required this.totalPayment,
    required this.remainingBalance,
    this.prepaymentAmount = 0,
    this.prepaymentFee = 0,
  });

  bool get hasPrepayment => prepaymentAmount > 0;
}

/// 대출 계산 결과 요약
class LoanCalculationResult {
  final RepaymentType type;
  final int loanAmount;
  final double annualRate;
  final int termMonths;
  final List<MonthlyPayment> schedule;
  final List<Prepayment> prepayments;
  final int totalInterest;
  final int totalPrepaymentFee;
  final int totalPayment; // 총 납부액 (원금+이자+수수료)

  const LoanCalculationResult({
    required this.type,
    required this.loanAmount,
    required this.annualRate,
    required this.termMonths,
    required this.schedule,
    required this.prepayments,
    required this.totalInterest,
    required this.totalPrepaymentFee,
    required this.totalPayment,
  });
}

/// 대출 계산 유틸리티
class LoanCalculatorUtil {
  LoanCalculatorUtil._();

  /// 스케줄 생성 (중도상환 포함)
  static LoanCalculationResult calculate({
    required int loanAmount,
    required double annualRate,
    required int termMonths,
    required RepaymentType type,
    List<Prepayment> prepayments = const [],
  }) {
    // 중도상환을 회차별로 매핑
    final prepayMap = <int, List<Prepayment>>{};
    for (final p in prepayments) {
      prepayMap.putIfAbsent(p.month, () => []).add(p);
    }

    final schedule = <MonthlyPayment>[];
    int remaining = loanAmount;
    final monthlyRate = annualRate / 12;
    int totalInterest = 0;
    int totalPrepaymentFee = 0;

    // 원리금균등: 월 상환액을 한번 계산 후 고정 (중도상환 시 재계산)
    int fixedMonthlyPayment = type == RepaymentType.equalPrincipalAndInterest
        ? _calcEqualPayment(loanAmount, monthlyRate, termMonths)
        : 0;
    bool needRecalc = false;

    for (int i = 1; i <= termMonths && remaining > 0; i++) {
      final interest = (remaining * monthlyRate).round();
      int principal;

      if (type == RepaymentType.equalPrincipalAndInterest) {
        // 중도상환 후 남은 잔액/기간으로 재계산
        if (needRecalc) {
          final remainingMonths = termMonths - i + 1;
          fixedMonthlyPayment = _calcEqualPayment(remaining, monthlyRate, remainingMonths);
          needRecalc = false;
        }
        principal = fixedMonthlyPayment - interest;
        if (principal > remaining) principal = remaining;
      } else if (type == RepaymentType.equalPrincipal) {
        // 원금균등: 남은 잔액 ÷ 남은 기간
        final remainingMonths = termMonths - i + 1;
        principal = (remaining / remainingMonths).round();
        if (principal > remaining) principal = remaining;
      } else {
        // 만기일시상환: 마지막 회차에만 원금 상환
        principal = (i == termMonths) ? remaining : 0;
      }

      remaining -= principal;
      if (remaining < 0) remaining = 0;
      totalInterest += interest;

      // 중도상환 처리
      int prepayAmount = 0;
      int prepayFee = 0;
      if (prepayMap.containsKey(i)) {
        for (final p in prepayMap[i]!) {
          int actualPrepay = p.amount;
          if (actualPrepay > remaining) actualPrepay = remaining;
          prepayAmount += actualPrepay;
          prepayFee += (actualPrepay * p.feeRate).round();
          remaining -= actualPrepay;
          if (remaining < 0) remaining = 0;
        }
        totalPrepaymentFee += prepayFee;
        needRecalc = true; // 다음 회차에서 월상환액 재계산
      }

      schedule.add(MonthlyPayment(
        month: i,
        principal: principal,
        interest: interest,
        totalPayment: principal + interest,
        remainingBalance: remaining,
        prepaymentAmount: prepayAmount,
        prepaymentFee: prepayFee,
      ));

      if (remaining == 0) break;
    }

    return LoanCalculationResult(
      type: type,
      loanAmount: loanAmount,
      annualRate: annualRate,
      termMonths: termMonths,
      schedule: schedule,
      prepayments: prepayments,
      totalInterest: totalInterest,
      totalPrepaymentFee: totalPrepaymentFee,
      totalPayment: loanAmount + totalInterest + totalPrepaymentFee,
    );
  }

  /// 원리금균등 월 상환액 계산 (내부)
  static int _calcEqualPayment(int principal, double monthlyRate, int months) {
    if (monthlyRate == 0) return (principal / months).round();
    final payment = principal *
        monthlyRate *
        pow(1 + monthlyRate, months) /
        (pow(1 + monthlyRate, months) - 1);
    return payment.round();
  }
}
