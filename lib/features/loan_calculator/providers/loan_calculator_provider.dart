import 'package:flutter/foundation.dart';
import 'package:budongsan_app/core/extensions/number_extensions.dart';
import 'package:budongsan_app/core/utils/calculators/loan_calculator_util.dart';
import 'package:budongsan_app/data/models/saved_calculation.dart';

class LoanCalculatorProvider extends ChangeNotifier {
  int _loanAmount = 0;
  double _annualRate = 0.0;
  int _termYears = 30;
  RepaymentType _repaymentType = RepaymentType.equalPrincipalAndInterest;
  final List<Prepayment> _prepayments = [];
  LoanCalculationResult? _result;
  DateTime? _calculatedAt;

  int get loanAmount => _loanAmount;
  double get annualRate => _annualRate;
  int get termYears => _termYears;
  int get termMonths => _termYears * 12;
  RepaymentType get repaymentType => _repaymentType;
  List<Prepayment> get prepayments => List.unmodifiable(_prepayments);
  LoanCalculationResult? get result => _result;

  String get repaymentTypeLabel {
    switch (_repaymentType) {
      case RepaymentType.equalPrincipalAndInterest:
        return '원리금균등';
      case RepaymentType.equalPrincipal:
        return '원금균등';
      case RepaymentType.bulletRepayment:
        return '만기일시';
    }
  }

  void setLoanAmount(int value) {
    _loanAmount = value;
    notifyListeners();
  }

  void setAnnualRate(double value) {
    _annualRate = value;
    notifyListeners();
  }

  void setTermYears(int value) {
    _termYears = value;
    notifyListeners();
  }

  void setRepaymentType(RepaymentType value) {
    _repaymentType = value;
    notifyListeners();
  }

  void addPrepayment({
    required int month,
    required int amount,
    required double feeRate,
  }) {
    _prepayments.add(Prepayment(
      month: month,
      amount: amount,
      feeRate: feeRate,
    ));
    _prepayments.sort((a, b) => a.month.compareTo(b.month));
    notifyListeners();
  }

  void removePrepayment(int index) {
    if (index >= 0 && index < _prepayments.length) {
      _prepayments.removeAt(index);
      notifyListeners();
    }
  }

  void clearPrepayments() {
    _prepayments.clear();
    notifyListeners();
  }

  bool calculate() {
    if (_loanAmount <= 0 || _annualRate <= 0 || _termYears <= 0) return false;

    _calculatedAt = DateTime.now();
    _result = LoanCalculatorUtil.calculate(
      loanAmount: _loanAmount,
      annualRate: _annualRate / 100, // UI에서 % 단위로 입력
      termMonths: termMonths,
      type: _repaymentType,
      prepayments: _prepayments,
    );
    notifyListeners();
    return true;
  }

  String get savedId => 'loan_${_calculatedAt?.millisecondsSinceEpoch ?? 0}';

  SavedCalculation toSavedCalculation() {
    final r = _result!;
    return SavedCalculation(
      id: savedId,
      type: 'loan',
      title: '총이자 ${r.totalInterest.toKoreanWon()}',
      subtitle: '대출 ${_loanAmount.toKoreanWon()} · $repaymentTypeLabel · ${_termYears}년',
      tags: [
        repaymentTypeLabel,
        '${_annualRate.toStringAsFixed(2)}%',
        '${_termYears}년',
        if (_prepayments.isNotEmpty) '중도상환 ${_prepayments.length}건',
      ],
      data: {
        'loanAmount': _loanAmount,
        'annualRate': _annualRate,
        'termYears': _termYears,
        'repaymentType': _repaymentType.index,
        'totalInterest': r.totalInterest,
        'totalPrepaymentFee': r.totalPrepaymentFee,
        'totalPayment': r.totalPayment,
        'schedule': r.schedule.map((p) => {
          'month': p.month,
          'principal': p.principal,
          'interest': p.interest,
          'totalPayment': p.totalPayment,
          'remainingBalance': p.remainingBalance,
          'prepaymentAmount': p.prepaymentAmount,
          'prepaymentFee': p.prepaymentFee,
        }).toList(),
      },
      savedAt: _calculatedAt ?? DateTime.now(),
    );
  }

  void reset() {
    _loanAmount = 0;
    _annualRate = 0.0;
    _termYears = 30;
    _repaymentType = RepaymentType.equalPrincipalAndInterest;
    _prepayments.clear();
    _result = null;
    notifyListeners();
  }
}
