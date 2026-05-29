import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _FeatureItem {
  final IconData icon;
  final String label;
  final String description;
  final String routeName;
  final Color iconColor;
  final Color iconBgColor;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.routeName,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_FeatureItem> _features = [
    _FeatureItem(
      icon: Icons.calculate_rounded,
      label: '대출계산',
      description: '원리금균등, 원금균등, 만기일시 상환 방식별 월 상환액과 총 이자를 계산합니다.',
      routeName: 'loanCalculator',
      iconColor: Color(0xFF2563EB),
      iconBgColor: Color(0xFFDBEAFE),
    ),
    _FeatureItem(
      icon: Icons.receipt_long_rounded,
      label: '취득세',
      description: '주택 수, 면적, 매매가 기반으로 취득세, 지방교육세, 농어촌특별세를 산출합니다.',
      routeName: 'acquisitionTax',
      iconColor: Color(0xFF7C3AED),
      iconBgColor: Color(0xFFEDE9FE),
    ),
    _FeatureItem(
      icon: Icons.payments_rounded,
      label: '월지출',
      description: '대출이자, 관리비, 보험료 등 월별 지출 항목을 시뮬레이션합니다.',
      routeName: 'monthlyExpense',
      iconColor: Color(0xFF059669),
      iconBgColor: Color(0xFFD1FAE5),
    ),
    _FeatureItem(
      icon: Icons.trending_up_rounded,
      label: '현금흐름',
      description: '임대수익과 지출을 비교하여 순현금흐름과 수익률을 분석합니다.',
      routeName: 'cashFlow',
      iconColor: Color(0xFFD97706),
      iconBgColor: Color(0xFFFEF3C7),
    ),
    _FeatureItem(
      icon: Icons.pie_chart_rounded,
      label: 'DSR',
      description: '총부채원리금상환비율(DSR)을 계산하여 대출 한도를 확인합니다.',
      routeName: 'dsr',
      iconColor: Color(0xFFDC2626),
      iconBgColor: Color(0xFFFEE2E2),
    ),
    _FeatureItem(
      icon: Icons.checklist_rounded,
      label: '체크리스트',
      description: '매물 방문 시 확인해야 할 항목들을 체크리스트로 관리합니다.',
      routeName: 'checklist',
      iconColor: Color(0xFF0891B2),
      iconBgColor: Color(0xFFCFFAFE),
    ),
    _FeatureItem(
      icon: Icons.compare_arrows_rounded,
      label: '비교',
      description: '여러 매물이나 시나리오의 계산 결과를 나란히 비교합니다.',
      routeName: 'comparison',
      iconColor: Color(0xFF6D28D9),
      iconBgColor: Color(0xFFEDE9FE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '부동산계산기',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        _ActionIcon(
                          icon: Icons.bookmark_outline_rounded,
                          onTap: () => context.pushNamed('savedCalculations'),
                        ),
                        const SizedBox(width: 4),
                        _ActionIcon(
                          icon: Icons.settings_outlined,
                          onTap: () => context.pushNamed('settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 24)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _features[index];
                    return _FeatureTile(item: item);
                  },
                  childCount: _features.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.pushNamed(item.routeName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? item.iconColor.withOpacity(0.15)
                          : item.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: item.iconColor,
                    ),
                  ),
                  _TooltipHelpIcon(message: item.description),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TooltipHelpIcon extends StatelessWidget {
  final String message;

  const _TooltipHelpIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: message,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onInverseSurface,
        height: 1.4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.help_outline_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }
}
