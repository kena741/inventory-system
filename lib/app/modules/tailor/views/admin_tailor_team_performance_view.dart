import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_tailor_team_performance_controller.dart';

class AdminTailorTeamPerformanceView extends GetView<AdminTailorTeamPerformanceController> {
  const AdminTailorTeamPerformanceView({super.key});

  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';

  static Color _heatBg(
    ColorScheme scheme,
    int count,
    int maxCount,
  ) {
    if (count <= 0) {
      return scheme.surfaceContainerLow.withValues(alpha: 0.35);
    }
    final t = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 1.0;
    return Color.lerp(
      scheme.surfaceContainerLow.withValues(alpha: 0.5),
      scheme.primaryContainer.withValues(alpha: 0.92),
      0.35 + 0.55 * t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor team performance'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(controller.error.value, textAlign: TextAlign.center),
            ),
          );
        }

        final weekStart = controller.weekStartDay;
        final weekEnd = weekStart.add(const Duration(days: 6));
        final cols = controller.columnTailorIds();
        final maxC = controller.maxCellCount(cols);

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: controller.goPrevWeek,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${_shortDate(weekStart)} – ${_shortDate(weekEnd)}, ${weekStart.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: controller.goNextWeek,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Completed orders by calendar day (local time). Darker cells = more deliveries.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (cols.isEmpty)
                Text(
                  controller.orders.isEmpty
                      ? 'No completed orders with a tailor assigned this week.'
                      : 'No tailor columns to display.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tableW =
                        (76 + cols.length * 72.0).clamp(constraints.maxWidth, 1200.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableW,
                        child: Table(
                          border: TableBorder.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          columnWidths: {
                            0: const FixedColumnWidth(76),
                            for (var i = 0; i < cols.length; i++)
                              i + 1: const FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                              children: [
                                _hCell(
                                  context,
                                  'Day',
                                  bold: true,
                                  scheme: scheme,
                                ),
                                ...cols.map(
                                  (id) => _hCell(
                                    context,
                                    controller.columnLabel(id),
                                    bold: true,
                                    scheme: scheme,
                                    center: true,
                                  ),
                                ),
                              ],
                            ),
                            for (var d = 0; d < 7; d++)
                              TableRow(
                                children: [
                                  _hCell(
                                    context,
                                    '${_dayShort[d]}\n${_shortDate(weekStart.add(Duration(days: d)))}',
                                    scheme: scheme,
                                  ),
                                  ...cols.map(
                                    (id) => _heatCell(
                                      context,
                                      scheme: scheme,
                                      count: controller.countForCell(id, d),
                                      pieces: controller.piecesForCell(id, d),
                                      maxCount: maxC,
                                    ),
                                  ),
                                ],
                              ),
                            TableRow(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                              ),
                              children: [
                                _hCell(
                                  context,
                                  'Tailor Σ',
                                  bold: true,
                                  scheme: scheme,
                                ),
                                ...cols.map(
                                  (id) => _hCell(
                                    context,
                                    controller.tailorWeekTotal(id).toString(),
                                    bold: true,
                                    scheme: scheme,
                                    center: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (cols.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Team deliveries by day',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (d) {
                    final dt = weekStart.add(Duration(days: d));
                    final n = controller.dayTotalDelivered(d);
                    return Tooltip(
                      message: _shortDate(dt),
                      child: Chip(
                        label: Text('${_dayShort[d]} · $n'),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MiniStat(
                      scheme: scheme,
                      label: 'Week total',
                      value: controller.weekGrandTotal().toString(),
                      icon: Icons.done_all_outlined,
                    ),
                    _MiniStat(
                      scheme: scheme,
                      label: 'Tailors on chart',
                      value: cols.length.toString(),
                      icon: Icons.groups_outlined,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Tip: assign tailors on each order so completions roll up here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static Widget _hCell(
    BuildContext context,
    String text, {
    required ColorScheme scheme,
    bool bold = false,
    bool center = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              height: 1.25,
              color: bold ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
      ),
    );
  }

  static Widget _heatCell(
    BuildContext context, {
    required ColorScheme scheme,
    required int count,
    required int pieces,
    required int maxCount,
  }) {
    final bg = _heatBg(scheme, count, maxCount);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (pieces > 0 && count > 0)
            Text(
              '$pieces pcs',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.scheme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
