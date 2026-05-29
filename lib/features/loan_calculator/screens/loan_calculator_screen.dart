import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/calculators/loan_calculator_util.dart';
import '../../saved_calculations/providers/saved_calculation_provider.dart';
import '../providers/loan_calculator_provider.dart';

class LoanCalculatorScreen extends StatelessWidget {
  const LoanCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoanCalculatorProvider(),
      child: const _LoanCalculatorBody(),
    );
  }
}

class _LoanCalculatorBody extends StatefulWidget {
  const _LoanCalculatorBody();

  @override
  State<_LoanCalculatorBody> createState() => _LoanCalculatorBodyState();
}

class _LoanCalculatorBodyState extends State<_LoanCalculatorBody> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final provider = context.read<LoanCalculatorProvider>();
    final success = provider.calculate();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대출금액, 금리, 기간을 모두 입력해주세요')),
      );
      return;
    }
    _showResultsBottomSheet();
  }

  void _showResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<LoanCalculatorProvider>(),
        child: const _ResultsBottomSheet(),
      ),
    );
  }

  void _onReset() {
    final provider = context.read<LoanCalculatorProvider>();
    provider.reset();
    _amountController.clear();
    _rateController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LoanCalculatorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('대출계산'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _onReset,
            tooltip: '초기화',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상환 방식
            _SectionLabel(label: '상환 방식'),
            const SizedBox(height: 8),
            _SegmentedSelector<RepaymentType>(
              selected: provider.repaymentType,
              options: const [
                (RepaymentType.equalPrincipalAndInterest, '원리금균등'),
                (RepaymentType.equalPrincipal, '원금균등'),
                (RepaymentType.bulletRepayment, '만기일시'),
              ],
              onChanged: provider.setRepaymentType,
            ),

            const SizedBox(height: 20),

            // 대출금액
            _SectionLabel(label: '대출금액'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CommaFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '대출금액을 입력하세요',
                suffixText: '원',
                suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _amountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _amountController.clear();
                          provider.setLoanAmount(0);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                final digits = value.replaceAll(',', '');
                provider.setLoanAmount(int.tryParse(digits) ?? 0);
              },
            ),
            if (_amountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  provider.loanAmount.toKoreanWon(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 금리 + 대출기간
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: '연 금리'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          hintText: '3.5',
                          suffixText: '%',
                          suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onChanged: (value) {
                          provider.setAnnualRate(double.tryParse(value) ?? 0);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: '대출기간'),
                      const SizedBox(height: 8),
                      _TermSelector(
                        years: provider.termYears,
                        onChanged: provider.setTermYears,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 중도상환 섹션
            _PrepaymentSection(provider: provider),

            const SizedBox(height: 24),

            // 계산 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _onCalculate,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '계산하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            if (provider.result != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _showResultsBottomSheet,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                  label: const Text('계산 결과 보기', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 중도상환 섹션
// ──────────────────────────────────────────

class _PrepaymentSection extends StatelessWidget {
  final LoanCalculatorProvider provider;
  const _PrepaymentSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '중도상환',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('추가', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          if (provider.prepayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '중도상환 없음',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ...provider.prepayments.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.month}회차 · ${p.amount.toKoreanWon()} · 수수료 ${(p.feeRate * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  InkWell(
                    onTap: () => provider.removePrepayment(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final monthCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '1.2');

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('중도상환 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: monthCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '상환 회차 (월)',
                  hintText: '12',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CommaFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: '상환 금액',
                  hintText: '10,000,000',
                  suffixText: '원',
                  suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: '중도상환 수수료',
                  hintText: '1.2',
                  suffixText: '%',
                  suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final month = int.tryParse(monthCtrl.text) ?? 0;
                final amount = int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
                final fee = double.tryParse(feeCtrl.text) ?? 0;
                if (month <= 0 || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('회차와 금액을 올바르게 입력해주세요')),
                  );
                  return;
                }
                provider.addPrepayment(
                  month: month,
                  amount: amount,
                  feeRate: fee / 100,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────
// 결과 바텀시트
// ──────────────────────────────────────────

class _ResultsBottomSheet extends StatelessWidget {
  const _ResultsBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LoanCalculatorProvider>();
    final result = provider.result;
    if (result == null) return const SizedBox.shrink();

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '계산 결과',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.repaymentTypeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (ctx) {
                    final savedProvider = ctx.watch<SavedCalculationProvider>();
                    final isSaved = savedProvider.isSaved(provider.savedId);
                    return IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        savedProvider.toggle(provider.toSavedCalculation());
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(isSaved ? '저장이 해제되었습니다' : '저장되었습니다'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      tooltip: isSaved ? '저장 해제' : '저장',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 요약 카드
          _SummaryCard(result: result),

          const SizedBox(height: 12),

          // 상환 스케줄 테이블
          Flexible(
            child: _ScheduleTable(schedule: result.schedule),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 요약 카드
// ──────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final LoanCalculationResult result;
  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _SummaryRow(label: '대출금액', value: result.loanAmount.toKoreanWon()),
          const SizedBox(height: 8),
          _SummaryRow(label: '금리', value: '${result.annualRate.toPercentFormat()}'),
          const SizedBox(height: 8),
          _SummaryRow(label: '기간', value: '${result.termMonths ~/ 12}년 (${result.termMonths}개월)'),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          _SummaryRow(
            label: '총 이자',
            value: result.totalInterest.toKoreanWon(),
            valueColor: theme.colorScheme.error,
          ),
          if (result.totalPrepaymentFee > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: '중도상환 수수료',
              value: result.totalPrepaymentFee.toKoreanWon(),
              valueColor: theme.colorScheme.error,
            ),
          ],
          const SizedBox(height: 8),
          _SummaryRow(
            label: '총 납부액',
            value: result.totalPayment.toKoreanWon(),
            isBold: true,
            valueColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.w700 : null,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 상환 스케줄 테이블
// ──────────────────────────────────────────

class _ScheduleTable extends StatelessWidget {
  final List<MonthlyPayment> schedule;
  const _ScheduleTable({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('회차', style: _headerStyle(theme)),
              ),
              Expanded(child: Text('원금', style: _headerStyle(theme), textAlign: TextAlign.right)),
              Expanded(child: Text('이자', style: _headerStyle(theme), textAlign: TextAlign.right)),
              Expanded(child: Text('월상환', style: _headerStyle(theme), textAlign: TextAlign.right)),
              Expanded(
                flex: 2,
                child: Text('잔액', style: _headerStyle(theme), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        // 데이터
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: bottomPadding + 24),
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final p = schedule[index];
              return _ScheduleRow(payment: p, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }

  TextStyle? _headerStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final MonthlyPayment payment;
  final bool isDark;

  const _ScheduleRow({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall;
    final hasPrepay = payment.hasPrepayment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: hasPrepay
            ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE))
            : null,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${payment.month}', style: style),
              ),
              Expanded(
                child: Text(
                  payment.principal.toCommaFormat(),
                  style: style,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  payment.interest.toCommaFormat(),
                  style: style?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  payment.totalPayment.toCommaFormat(),
                  style: style?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  payment.remainingBalance.toCommaFormat(),
                  style: style,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (hasPrepay)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 12, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '중도상환 ${payment.prepaymentAmount.toKoreanWon()}',
                    style: style?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (payment.prepaymentFee > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(수수료 ${payment.prepaymentFee.toCommaFormat()}원)',
                      style: style?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 기간 선택 드롭다운
// ──────────────────────────────────────────

class _TermSelector extends StatelessWidget {
  final int years;
  final ValueChanged<int> onChanged;

  const _TermSelector({required this.years, required this.onChanged});

  static const _options = [5, 10, 15, 20, 25, 30, 35, 40];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      value: _options.contains(years) ? years : 30,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: _options.map((y) {
        return DropdownMenuItem(
          value: y,
          child: Text('${y}년', style: theme.textTheme.bodyMedium),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

// ──────────────────────────────────────────
// 공용 위젯
// ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _SegmentedSelector<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _SegmentedSelector({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.$2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 콤마 포매터
// ──────────────────────────────────────────

class _CommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final number = int.tryParse(text);
    if (number == null) return oldValue;
    final formatted = number.toCommaFormat();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
