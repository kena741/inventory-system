import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';
import '../../../models/erp/location_model.dart';
import '../controllers/expenses_controller.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  late final ExpensesController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _categoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    controller = Get.find<ExpensesController>();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refreshExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_expenses',
        onPressed: () => _showCreateExpense(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return _ErrorState(
            message: controller.error.value,
            onRetry: controller.refreshExpenses,
          );
        }

        final all = controller.expenses.toList(growable: false);
        final categories = <String>{
          for (final e in all)
            (e['category']?.toString().trim().isEmpty ?? true)
                ? 'other'
                : e['category'].toString().trim(),
        }.toList()
          ..sort();

        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = all.where((e) {
          final cat = (e['category']?.toString().trim().isEmpty ?? true)
              ? 'other'
              : e['category'].toString().trim();
          if (_categoryFilter != 'all' && cat != _categoryFilter) return false;
          if (query.isEmpty) return true;
          final desc = (e['description']?.toString() ?? '').toLowerCase();
          final amount = (e['amount']?.toString() ?? '').toLowerCase();
          return cat.toLowerCase().contains(query) ||
              desc.contains(query) ||
              amount.contains(query);
        }).toList(growable: false);

        final total = filtered.fold<num>(0, (sum, e) {
          final v = e['amount'];
          if (v is num) return sum + v;
          return sum + (num.tryParse(v?.toString() ?? '') ?? 0);
        });

        return RefreshIndicator(
          onRefresh: controller.refreshExpenses,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        title: 'Total',
                        value: _formatAmount(total),
                        subtitle:
                            '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search category, amount, description',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () => _searchCtrl.clear(),
                                  icon: const Icon(Icons.close),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'All',
                              selected: _categoryFilter == 'all',
                              onTap: () => setState(() => _categoryFilter = 'all'),
                            ),
                            for (final c in categories)
                              _CategoryChip(
                                label: _titleCase(c),
                                selected: _categoryFilter == c,
                                onTap: () => setState(() => _categoryFilter = c),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: _EmptyState(
                            title: all.isEmpty ? 'No expenses yet' : 'No results',
                            subtitle: all.isEmpty
                                ? 'Tap + to add your first expense.'
                                : 'Try a different category or search.',
                            icon: Icons.inbox_outlined,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (filtered.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return _ExpenseCard(expense: e);
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showCreateExpense(BuildContext context) async {
    final repo = ErpRepository();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locations = await repo.listLocations();
    if (!context.mounted) return;

    String category = 'other';
    String? locationId;

    await showDialog<void>(
      context: context,
      builder: (_) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('New expense'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'rent', child: Text('Rent')),
                      DropdownMenuItem(value: 'salary', child: Text('Salary')),
                      DropdownMenuItem(value: 'transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => category = v ?? 'other',
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: locationId,
                    items: locations
                        .map(
                          (LocationModel l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => locationId = v,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Select a location' : null,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (v) {
                      final amount = num.tryParse((v ?? '').trim()) ?? 0;
                      if (amount <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final amount = num.tryParse(amountCtrl.text.trim()) ?? 0;
                await controller.createExpense(
                  category: category,
                  amount: amount,
                  locationId: locationId!,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? theme.colorScheme.onPrimary : null,
        ),
        selectedColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = (expense['category']?.toString().trim().isEmpty ?? true)
        ? 'other'
        : expense['category'].toString().trim();
    final amount = expense['amount'];
    final amountNum = amount is num ? amount : (num.tryParse(amount?.toString() ?? '') ?? 0);
    final description = (expense['description']?.toString() ?? '').trim();
    final dateLabel = _formatExpenseDate(expense['date']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(category),
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleCase(category),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _formatAmount(amountNum),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (description.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(num amount) {
  if (amount % 1 == 0) return amount.toInt().toString();
  return amount.toStringAsFixed(2);
}

String _formatExpenseDate(dynamic raw) {
  if (raw == null) return 'Unknown date';
  try {
    final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  } catch (_) {
    return raw.toString();
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'rent':
      return Icons.home_work_outlined;
    case 'salary':
      return Icons.payments_outlined;
    case 'transport':
      return Icons.local_shipping_outlined;
    case 'utilities':
      return Icons.bolt_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

String _titleCase(String v) {
  final s = v.trim();
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

