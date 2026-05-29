import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/calculators/acquisition_tax_util.dart';
import '../../saved_calculations/providers/saved_calculation_provider.dart';
import '../providers/acquisition_tax_provider.dart';

class AcquisitionTaxScreen extends StatelessWidget {
  const AcquisitionTaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcquisitionTaxProvider(),
      child: const _AcquisitionTaxBody(),
    );
  }
}

class _AcquisitionTaxBody extends StatefulWidget {
  const _AcquisitionTaxBody();

  @override
  State<_AcquisitionTaxBody> createState() => _AcquisitionTaxBodyState();
}

class _AcquisitionTaxBodyState extends State<_AcquisitionTaxBody> {
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final provider = context.read<AcquisitionTaxProvider>();
    if (provider.price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취득가액을 입력하세요')),
      );
      return;
    }

    provider.calculate();

    // Bottom Sheet 열기
    _showResultsBottomSheet();
  }

  void _showResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: context.read<AcquisitionTaxProvider>(),
          child: const _ResultsBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AcquisitionTaxProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('취득세 계산'),
        actions: [
          if (provider.results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list_alt_rounded),
              onPressed: _showResultsBottomSheet,
              tooltip: '계산 결과 보기',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              provider.reset();
              _priceController.clear();
            },
            tooltip: '초기화',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 부동산 유형 선택
            _SectionLabel(label: '부동산 유형'),
            const SizedBox(height: 8),
            _SegmentedSelector<PropertyType>(
              selected: provider.propertyType,
              options: const [
                (PropertyType.housing, '주택'),
                (PropertyType.nonHousing, '주택 외'),
              ],
              onChanged: provider.setPropertyType,
            ),

            const SizedBox(height: 20),

            // 취득가액 입력
            _SectionLabel(label: '취득가액'),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CommaTextInputFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '매매가를 입력하세요',
                suffixText: '원',
                suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _priceController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _priceController.clear();
                          provider.setPrice(0);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                final digits = value.replaceAll(',', '');
                final price = int.tryParse(digits) ?? 0;
                provider.setPrice(price);
              },
            ),
            if (_priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  provider.price.toKoreanWon(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 주택: 세부 옵션
            if (provider.propertyType == PropertyType.housing) ...[
              // 주택 수
              _SectionLabel(label: '주택 수'),
              const SizedBox(height: 8),
              _SegmentedSelector<HouseCount>(
                selected: provider.houseCount,
                options: const [
                  (HouseCount.one, '1주택'),
                  (HouseCount.two, '2주택'),
                  (HouseCount.three, '3주택'),
                  (HouseCount.four, '4주택+'),
                ],
                onChanged: provider.setHouseCount,
              ),

              const SizedBox(height: 20),

              // 지역 구분 + 전용면적 (가로 배치)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: '지역'),
                        const SizedBox(height: 8),
                        _SegmentedSelector<AreaType>(
                          selected: provider.areaType,
                          options: const [
                            (AreaType.regulated, '조정'),
                            (AreaType.nonRegulated, '비규제'),
                          ],
                          onChanged: provider.setAreaType,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: '면적'),
                        const SizedBox(height: 8),
                        _SegmentedSelector<bool>(
                          selected: provider.isOver85sqm,
                          options: const [
                            (false, '85㎡↓'),
                            (true, '85㎡↑'),
                          ],
                          onChanged: provider.setIsOver85sqm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 생애최초
              _FirstTimeBuyerSection(provider: provider),
            ],

            // 주택 외: 취득유형 선택
            if (provider.propertyType == PropertyType.nonHousing) ...[
              _SectionLabel(label: '취득 유형'),
              const SizedBox(height: 8),
              _NonHousingTypeSelector(provider: provider),
            ],

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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // 결과 있으면 하단에 안내 표시
            if (provider.results.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _showResultsBottomSheet,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                  label: Text(
                    '계산 결과 ${provider.results.length}건 보기',
                    style: const TextStyle(fontSize: 13),
                  ),
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
// 주택 외 취득유형 선택
// ──────────────────────────────────────────

class _NonHousingTypeSelector extends StatelessWidget {
  final AcquisitionTaxProvider provider;
  const _NonHousingTypeSelector({required this.provider});

  static const _options = <(NonHousingType, String, String)>[
    (NonHousingType.purchase, '매매', '토지, 건물 등'),
    (NonHousingType.originalInherit, '신축/상속', '원시취득, 상속(농지 외)'),
    (NonHousingType.gift, '증여', '무상취득'),
    (NonHousingType.farmlandNew, '농지(신규)', '매매'),
    (NonHousingType.farmlandSelfFarm, '농지(자경)', '2년이상 자경'),
    (NonHousingType.farmlandInherit, '농지(상속)', '상속'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((option) {
        final isSelected = option.$1 == provider.nonHousingType;
        return GestureDetector(
          onTap: () => provider.setNonHousingType(option.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.$2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  option.$3,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────
// 생애최초 섹션
// ──────────────────────────────────────────

class _FirstTimeBuyerSection extends StatelessWidget {
  final AcquisitionTaxProvider provider;
  const _FirstTimeBuyerSection({required this.provider});

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '생애최초 주택구입',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: '12억원 이하 주택, 감면한도 200만원\n(2028.12.31까지, 지방세특례제한법 §36의3)',
                    triggerMode: TooltipTriggerMode.tap,
                    preferBelow: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: provider.isFirstTimeBuyer,
                onChanged: provider.setIsFirstTimeBuyer,
              ),
            ],
          ),
          if (provider.isFirstTimeBuyer) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '인구감소지역 (한도 300만원)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch.adaptive(
                  value: provider.isDepopulationArea,
                  onChanged: provider.setIsDepopulationArea,
                ),
              ],
            ),
          ],
        ],
      ),
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
                  color: isSelected
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option.$2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.onSurface
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
// Bottom Sheet
// ──────────────────────────────────────────

class _ResultsBottomSheet extends StatefulWidget {
  const _ResultsBottomSheet();

  @override
  State<_ResultsBottomSheet> createState() => _ResultsBottomSheetState();
}

class _ResultsBottomSheetState extends State<_ResultsBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<AcquisitionTaxProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '계산 결과 (${provider.results.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (provider.results.length > 1)
                      Text(
                        '← 스와이프 →',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () {
                        provider.clearResults();
                        Navigator.of(context).pop();
                      },
                      tooltip: '전체 삭제',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 결과 카드 리스트 (가로 스크롤)
          Flexible(
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: bottomPadding + 24,
              ),
              itemCount: provider.results.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final snapshot = provider.results[index];
                return _ResultCard(
                  snapshot: snapshot,
                  index: index,
                  onRemove: () {
                    provider.removeResult(index);
                    if (provider.results.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 결과 카드
// ──────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final AcquisitionTaxSnapshot snapshot;
  final int index;
  final VoidCallback onRemove;

  const _ResultCard({
    required this.snapshot,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final result = snapshot.result;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 입력값 요약 + 삭제 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Tag(label: snapshot.price.toKoreanWon()),
                    ...snapshot.tagLabels.map((label) {
                      final isHighlight = label.contains('생애최초');
                      return _Tag(label: label, highlight: isHighlight);
                    }),
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

          const SizedBox(height: 16),

          // 본문: 세금 내역
          _TaxRow(label: '취득세', rate: result.acquisitionTaxRate, value: result.acquisitionTax),
          if (result.reductionAmount > 0) ...[            const SizedBox(height: 4),
            _ReductionRow(
              beforeAmount: result.acquisitionTaxBeforeReduction,
              reductionAmount: result.reductionAmount,
            ),
          ],
          const SizedBox(height: 8),
          _TaxRow(label: '농어촌특별세', rate: result.ruralSpecialTaxRate, value: result.ruralSpecialTax),
          const SizedBox(height: 8),
          _TaxRow(label: '지방교육세', rate: result.localEducationTaxRate, value: result.localEducationTax),

          const SizedBox(height: 14),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 14),

          // 총액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 납부세액',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    result.totalTax.toWonFormat(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    result.totalTax.toKoreanWon(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 하단: 액션 버튼들
          Builder(
            builder: (context) {
              final savedProvider = context.watch<SavedCalculationProvider>();
              final isSaved = savedProvider.isSaved(snapshot.id);
              return Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      label: isSaved ? '저장됨' : '저장',
                      highlight: isSaved,
                      onTap: () {
                        savedProvider.toggle(snapshot.toSavedCalculation());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSaved ? '저장이 해제되었습니다' : '저장되었습니다'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.image_outlined,
                      label: '이미지',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이미지로 저장되었습니다')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF로 저장되었습니다')),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool highlight;
  const _Tag({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE))
            : (isDark ? const Color(0xFF334155) : Colors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlight
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ReductionRow extends StatelessWidget {
  final int beforeAmount;
  final int reductionAmount;

  const _ReductionRow({
    required this.beforeAmount,
    required this.reductionAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_downward_rounded,
          size: 12,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '감면 -${reductionAmount.toWonFormat()}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '(감면 전 ${beforeAmount.toWonFormat()})',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _TaxRow extends StatelessWidget {
  final String label;
  final double rate;
  final int value;

  const _TaxRow({
    required this.label,
    required this.rate,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${(rate * 100).toStringAsFixed(2)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value.toWonFormat(),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: isDark ? const Color(0xFF334155) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 콤마 자동 삽입 포매터
// ──────────────────────────────────────────

class _CommaTextInputFormatter extends TextInputFormatter {
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
