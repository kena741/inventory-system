import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/vendors_controller.dart';

class VendorsView extends GetView<VendorsController> {
  const VendorsView({super.key});

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'V';
    final a = parts.first.characters.firstOrNull ?? 'V';
    final b = parts.length > 1 ? (parts[1].characters.firstOrNull ?? '') : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_vendors',
        onPressed: () => _showVendorDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.error.value,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshVendors,
          child: controller.vendors.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('No vendors yet')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: controller.vendors.length,
                  itemBuilder: (context, index) {
                    final v = controller.vendors[index];
                    final id = (v['id'] ?? '').toString();
                    final name = (v['name'] ?? '').toString();
                    final phone = (v['phone'] ?? '').toString().trim();
                    final address = (v['address'] ?? '').toString().trim();
                    final displayName = name.isEmpty ? 'Vendor' : name;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showVendorDialog(context, initial: v),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    scheme.primary.withValues(alpha: 0.12),
                                foregroundColor: scheme.primary,
                                child: Text(
                                  _initials(displayName),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (phone.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 16,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              phone,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (phone.isNotEmpty && address.isNotEmpty)
                                      const SizedBox(height: 4),
                                    if (address.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              address,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Actions',
                        onSelected: (action) async {
                          switch (action) {
                            case 'edit':
                              await _showVendorDialog(
                                context,
                                initial: v,
                              );
                            case 'delete':
                              if (id.isEmpty) return;
                              await _confirmDelete(
                                context,
                                id,
                                name,
                              );
                          }
                        },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      }),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete vendor?'),
        content: Text(
          name.trim().isEmpty
              ? 'This vendor will be permanently deleted.'
              : '"$name" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteVendor(id);
    }
  }

  Future<void> _showVendorDialog(
    BuildContext context, {
    Map<String, dynamic>? initial,
  }) async {
    final isEdit = initial != null;
    final id = (initial?['id'] ?? '').toString();

    final nameCtrl = TextEditingController(
      text: (initial?['name'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (initial?['phone'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: (initial?['address'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit vendor' : 'Add vendor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                textInputAction: TextInputAction.done,
                minLines: 1,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final phone = phoneCtrl.text.trim();
              final address = addressCtrl.text.trim();

              if (isEdit && id.isNotEmpty) {
                await controller.updateVendor(
                  id: id,
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                  address: address.isEmpty ? null : address,
                );
              } else {
                await controller.createVendor(
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                  address: address.isEmpty ? null : address,
                );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }
}
