import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/locations_controller.dart';

class LocationsView extends GetView<LocationsController> {
  const LocationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_locations',
        onPressed: () => _showCreateLocation(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        if (controller.locations.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshLocations,
            child: ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('No locations yet')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshLocations,
          child: ListView.separated(
            itemCount: controller.locations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final loc = controller.locations[index];
              return ListTile(
                title: Text(loc.name),
                subtitle: Text(loc.type.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.deleteLocation(loc.id),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showCreateLocation(BuildContext context) async {
    final nameCtrl = TextEditingController();
    var type = 'warehouse';

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(
                    value: 'manufacturing',
                    child: Text('Manufacturing'),
                  ),
                  DropdownMenuItem(
                    value: 'warehouse',
                    child: Text('Warehouse'),
                  ),
                  DropdownMenuItem(
                    value: 'retail',
                    child: Text('Retail'),
                  ),
                ],
                onChanged: (v) => type = v ?? 'warehouse',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
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
                await controller.createLocation(name: name, type: type);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

