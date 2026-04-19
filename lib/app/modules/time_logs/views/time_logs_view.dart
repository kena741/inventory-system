import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/time_logs_controller.dart';

class TimeLogsView extends GetView<TimeLogsController> {
  const TimeLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return Center(child: Text(controller.error.value));
      }

      final clockedIn = controller.isClockedIn.value;
      final active = controller.activeClockIn.value;

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: const Icon(Icons.timer_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clock in/out',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              clockedIn
                                  ? 'Clocked in since ${active?.toLocal().toString() ?? ''}'
                                  : 'Not clocked in',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.toggleClock,
                      icon: Icon(clockedIn
                          ? Icons.logout_outlined
                          : Icons.login_outlined),
                      label: Text(clockedIn ? 'Clock out' : 'Clock in'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (controller.logs.isEmpty)
              const Text('No time logs yet')
            else
              ...controller.logs.map((l) {
                final cin = l['clock_in']?.toString() ?? '';
                final cout = l['clock_out']?.toString() ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(cin.isEmpty ? 'Clock in' : cin),
                    subtitle: Text(cout.isEmpty ? 'Active' : 'Clock out: $cout'),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}

