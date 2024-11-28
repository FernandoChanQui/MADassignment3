import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/order_plan.dart';
import 'edit_order_screen.dart';

class AllOrdersScreen extends StatelessWidget {
  const AllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
      ),
      body: FutureBuilder<List<OrderPlan>>(
        future: DatabaseHelper.instance.getAllOrderPlans(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              
              // Group items by name and count their quantities
              final itemQuantities = <String, int>{};
              for (var item in order.items) {
                itemQuantities[item.name] = (itemQuantities[item.name] ?? 0) + 1;
              }
              
              // Create a formatted string of items with their quantities
              final itemsString = itemQuantities.entries
                .map((entry) => '${entry.key} x${entry.value}')
                .join(', ');

              return ListTile(
                title: Text(order.date),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost: \$${order.targetCost.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Items: $itemsString',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditOrderScreen(order: order),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}