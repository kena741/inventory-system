import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/tailor_performance_controller.dart';

class TailorPerformanceView extends GetView<TailorPerformanceController> {
  const TailorPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      controller.periodAnchor.value;
      controller.range.value;

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return Center(child: Text(controller.error.value));
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: const Icon(Icons.insights_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tailor performance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Delivered orders · dates below are local',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PerformanceRange>(
              segments: const [
                ButtonSegment(value: PerformanceRange.day, label: Text('Day')),
                ButtonSegment(value: PerformanceRange.week, label: Text('Week')),
                ButtonSegment(value: PerformanceRange.month, label: Text('Month')),
              ],
              selected: {controller.range.value},
              onSelectionChanged: (s) => controller.setRange(s.first),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous period',
                  onPressed: () => controller.shiftPeriod(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: controller.pickAnchorDate,
                    child: Text(
                      controller.anchorSummary,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next period',
                  onPressed: () => controller.shiftPeriod(1),
                  icon: const Icon(Icons.chevron_right),
                ),
                TextButton(
                  onPressed: controller.goToToday,
                  child: const Text('Today'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.periodCaption,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      foregroundColor: scheme.primary,
                      child: const Icon(Icons.check_circle_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivered',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.deliveredCount.value.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Breakdown by day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Each row is the calendar day we attributed the completion to (completed → order → created date).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            if (controller.deliveredByDay.isEmpty)
              const Text('No delivered orders in this period')
            else
              ...controller.deliveredByDay.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                      TailorPerformanceController.formatDayBucketTitle(e.key),
                    ),
                    subtitle: e.key == '__unknown__'
                        ? Text(
                            'Could not derive a calendar day from completion, order, or created timestamps.',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          )
                        : null,
                    trailing: Text(
                      e.value.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

