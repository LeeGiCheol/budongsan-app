import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budongsan_app/core/extensions/number_extensions.dart';
import 'package:budongsan_app/data/models/saved_calculation.dart';
import 'package:budongsan_app/features/saved_calculations/providers/saved_calculation_provider.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  State<SavedCalculationsScreen> createState() => _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  String _selectedCategory = 'all';

  static const _categories = <(String, String, IconData)>[
    ('all', '전체', Icons.grid_view_rounded),
    ('acquisition_tax', '취득세', Icons.receipt_long_rounded),
    ('loan', '대출', Icons.calculate_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SavedCalculationProvider>();
    final allItems = provider.items;
    final filteredItems = _selectedCategory == 'all'
        ? allItems
        : allItems.where((e) => e.type == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 계산'),
        actions: [
          if (allItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _showClearDialog(context, provider),
              tooltip: '전체 삭제',
            ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = cat.$1 == _selectedCategory;
                final count = cat.$1 == 'all'
                    ? allItems.length
                    : allItems.where((e) => e.type == cat.$1).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(cat.$3, size: 16),
                    label: Text('${cat.$2} $count'),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat.$1),
                  ),
                );
              }).toList(),
            ),
          ),

          // 리스트
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '저장된 계산이 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '계산 결과에서 저장 버튼을 눌러보세요',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _SavedItemCard(
                        item: item,
                        onRemove: () => provider.remove(item.id),
                        onTap: () => _showDetailSheet(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, SavedCalculation item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailBottomSheet(item: item),
    );
  }

  void _showClearDialog(BuildContext context, SavedCalculationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('저장된 모든 계산을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 카테고리별 아이콘/색상 매핑
// ──────────────────────────────────────────

(IconData, Color) _categoryMeta(String type) {
  switch (type) {
    case 'acquisition_tax':
      return (Icons.receipt_long_rounded, const Color(0xFF7C3AED));
    case 'loan':
      return (Icons.calculate_rounded, const Color(0xFF2563EB));
    default:
      return (Icons.bookmark_rounded, const Color(0xFF6B7280));
  }
}

class _SavedItemCard extends StatelessWidget {
  final SavedCalculation item;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _SavedItemCard({required this.item, required this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (catIcon, catColor) = _categoryMeta(item.type);

    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 아이콘
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, size: 18, color: catColor),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onRemove,
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
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 상세 바텀시트
// ──────────────────────────────────────────

class _DetailBottomSheet extends StatelessWidget {
  final SavedCalculation item;
  const _DetailBottomSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (catIcon, catColor) = _categoryMeta(item.type);
    final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(item.savedAt);
    final isLoan = item.type == 'loan';
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: isLoan ? maxHeight : double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, size: 20, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 태그
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 상세 내역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildSummaryContent(theme),
            ),
          ),

          // 대출: 월별 스케줄 테이블
          if (isLoan) ...[
            const SizedBox(height: 12),
            Flexible(
              child: _buildScheduleTable(theme, isDark, context),
            ),
          ],

          if (!isLoan) ...[
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '저장일시: $dateStr',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryContent(ThemeData theme) {
    switch (item.type) {
      case 'acquisition_tax':
        return _buildAcquisitionTaxDetail(theme);
      case 'loan':
        return _buildLoanSummary(theme);
      default:
        return const Text('상세 정보 없음');
    }
  }

  Widget _buildAcquisitionTaxDetail(ThemeData theme) {
    final d = item.data;
    final price = (d['price'] as num?)?.toInt() ?? 0;
    final acqTax = (d['acquisitionTax'] as num?)?.toInt() ?? 0;
    final ruralTax = (d['ruralSpecialTax'] as num?)?.toInt() ?? 0;
    final localEduTax = (d['localEducationTax'] as num?)?.toInt() ?? 0;
    final totalTax = (d['totalTax'] as num?)?.toInt() ?? 0;
    final acqRate = (d['acquisitionTaxRate'] as num?)?.toDouble() ?? 0;
    final ruralRate = (d['ruralSpecialTaxRate'] as num?)?.toDouble() ?? 0;
    final localEduRate = (d['localEducationTaxRate'] as num?)?.toDouble() ?? 0;
    final reductionAmount = (d['reductionAmount'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        _DetailRow(label: '취득가액', value: price.toKoreanWon()),
        const SizedBox(height: 10),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 10),
        _DetailRow(
          label: '취득세 (${acqRate.toPercentFormat()})',
          value: acqTax.toKoreanWon(),
        ),
        if (reductionAmount > 0) ...[
          const SizedBox(height: 6),
          _DetailRow(
            label: '└ 생애최초 감면',
            value: '-${reductionAmount.toKoreanWon()}',
            valueColor: const Color(0xFF16A34A),
          ),
        ],
        const SizedBox(height: 6),
        _DetailRow(
          label: '농어촌특별세 (${ruralRate.toPercentFormat()})',
          value: ruralTax.toKoreanWon(),
        ),
        const SizedBox(height: 6),
        _DetailRow(
          label: '지방교육세 (${localEduRate.toPercentFormat()})',
          value: localEduTax.toKoreanWon(),
        ),
        const SizedBox(height: 10),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 10),
        _DetailRow(
          label: '총 납부세액',
          value: totalTax.toKoreanWon(),
          isBold: true,
          valueColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            totalTax.toWonFormat(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanSummary(ThemeData theme) {
    final d = item.data;
    final loanAmount = (d['loanAmount'] as num?)?.toInt() ?? 0;
    final annualRate = (d['annualRate'] as num?)?.toDouble() ?? 0;
    final termYears = (d['termYears'] as num?)?.toInt() ?? 0;
    final totalInterest = (d['totalInterest'] as num?)?.toInt() ?? 0;
    final totalPrepaymentFee = (d['totalPrepaymentFee'] as num?)?.toInt() ?? 0;
    final totalPayment = (d['totalPayment'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        _DetailRow(label: '대출금액', value: loanAmount.toKoreanWon()),
        const SizedBox(height: 6),
        _DetailRow(label: '연 금리', value: '${annualRate.toStringAsFixed(2)}%'),
        const SizedBox(height: 6),
        _DetailRow(label: '대출기간', value: '$termYears년 (${termYears * 12}개월)'),
        const SizedBox(height: 10),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 10),
        _DetailRow(
          label: '총 이자',
          value: totalInterest.toKoreanWon(),
          valueColor: theme.colorScheme.error,
        ),
        if (totalPrepaymentFee > 0) ...[
          const SizedBox(height: 6),
          _DetailRow(
            label: '중도상환 수수료',
            value: totalPrepaymentFee.toKoreanWon(),
            valueColor: theme.colorScheme.error,
          ),
        ],
        const SizedBox(height: 10),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 10),
        _DetailRow(
          label: '총 납부액',
          value: totalPayment.toKoreanWon(),
          isBold: true,
          valueColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildScheduleTable(ThemeData theme, bool isDark, BuildContext context) {
    final rawSchedule = item.data['schedule'] as List?;
    if (rawSchedule == null || rawSchedule.isEmpty) {
      return const SizedBox.shrink();
    }

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // 테이블 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('회차', style: headerStyle)),
              Expanded(child: Text('원금', style: headerStyle, textAlign: TextAlign.right)),
              Expanded(child: Text('이자', style: headerStyle, textAlign: TextAlign.right)),
              Expanded(child: Text('월상환', style: headerStyle, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('잔액', style: headerStyle, textAlign: TextAlign.right)),
            ],
          ),
        ),
        // 테이블 바디
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: bottomPadding + 16),
            itemCount: rawSchedule.length,
            itemBuilder: (context, index) {
              final row = Map<String, dynamic>.from(rawSchedule[index] as Map);
              final month = (row['month'] as num?)?.toInt() ?? 0;
              final principal = (row['principal'] as num?)?.toInt() ?? 0;
              final interest = (row['interest'] as num?)?.toInt() ?? 0;
              final total = (row['totalPayment'] as num?)?.toInt() ?? 0;
              final remaining = (row['remainingBalance'] as num?)?.toInt() ?? 0;
              final prepayAmt = (row['prepaymentAmount'] as num?)?.toInt() ?? 0;
              final prepayFee = (row['prepaymentFee'] as num?)?.toInt() ?? 0;
              final hasPrepay = prepayAmt > 0;

              final style = theme.textTheme.labelSmall;

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
                        SizedBox(width: 40, child: Text('$month', style: style)),
                        Expanded(
                          child: Text(principal.toCommaFormat(), style: style, textAlign: TextAlign.right),
                        ),
                        Expanded(
                          child: Text(
                            interest.toCommaFormat(),
                            style: style?.copyWith(color: theme.colorScheme.error),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            total.toCommaFormat(),
                            style: style?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(remaining.toCommaFormat(), style: style, textAlign: TextAlign.right),
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
                              '중도상환 ${prepayAmt.toKoreanWon()}',
                              style: style?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (prepayFee > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(수수료 ${prepayFee.toCommaFormat()}원)',
                                style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
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
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w700 : null,
            ),
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
