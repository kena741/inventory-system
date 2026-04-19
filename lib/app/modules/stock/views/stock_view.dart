import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../raw_materials/bindings/raw_materials_binding.dart';
import '../../raw_materials/views/raw_materials_view.dart';

class StockView extends StatelessWidget {
  const StockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Stock',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add new materials and manage stock-related setup.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    RawMaterialsBinding().dependencies();
                    Get.to(
                      () => Scaffold(
                        appBar: AppBar(title: const Text('Raw Materials')),
                        body: const RawMaterialsView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add item to stock'),
                ),
              ),
              const SizedBox(height: 12),
              
            ],
          ),
        ),
      ),
    );
  }
}

