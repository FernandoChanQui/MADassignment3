import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../database/database_helper.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderPlan order;

  const EditOrderScreen({super.key, required this.order});

  @override
  _EditOrderScreenState createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late double _targetCost;
  late Map<FoodItem, int> _selectedItems;
  final TextEditingController _targetCostController = TextEditingController();
  List<FoodItem> _availableFoodItems = [];

  @override
  void initState() {
    super.initState();
    _targetCost = widget.order.targetCost;
    _targetCostController.text = _targetCost.toStringAsFixed(2);
    
    // Convert items to quantity map
    _selectedItems = {};
    for (var item in widget.order.items) {
      _selectedItems[item] = (_selectedItems[item] ?? 0) + 1;
    }
    
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    final items = await DatabaseHelper.instance.getAllFoodItems();
    setState(() {
      _availableFoodItems = items;
    });
  }

  double _calculateTotalCost() {
    return _selectedItems.entries.fold(0, (sum, entry) => sum + (entry.key.cost * entry.value));
  }

  void _addFoodItem(FoodItem item) {
    final totalCost = _calculateTotalCost() + item.cost;
    
    if (totalCost <= _targetCost) {
      setState(() {
        _selectedItems[item] = (_selectedItems[item] ?? 0) + 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adding this item would exceed the target cost'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFoodItem(FoodItem item) {
    setState(() {
      final currentQuantity = _selectedItems[item] ?? 0;
      if (currentQuantity > 1) {
        _selectedItems[item] = currentQuantity - 1;
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  void _saveChanges() async {
    // Convert the Map to a list of items for OrderPlan
    final itemsList = _selectedItems.entries.expand((entry) => 
      List.filled(entry.value, entry.key)
    ).toList();

    final updatedOrder = OrderPlan(
      date: widget.order.date,
      targetCost: _targetCost,
      items: itemsList,
    );

    await DatabaseHelper.instance.updateOrderPlan(updatedOrder);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _deleteOrder() async {
    await DatabaseHelper.instance.deleteOrderPlan(widget.order.date);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteOrder,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _targetCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Cost',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _targetCost = double.tryParse(value) ?? _targetCost;
                  _targetCostController.text = _targetCost.toStringAsFixed(2);
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // Selected Items List
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Selected Items',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _selectedItems.length,
                              itemBuilder: (context, index) {
                                final item = _selectedItems.keys.elementAt(index);
                                final quantity = _selectedItems[item]!;
                                return ListTile(
                                  title: Text('${item.name} x$quantity'),
                                  subtitle: Text('\$${(item.cost * quantity).toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _removeFoodItem(item),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Total Cost: \$${_calculateTotalCost().toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Available Items List
                  Expanded(
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Available Items',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _availableFoodItems.length,
                              itemBuilder: (context, index) {
                                final item = _availableFoodItems[index];
                                return ListTile(
                                  title: Text(item.name),
                                  subtitle: Text('\$${item.cost.toStringAsFixed(2)}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _addFoodItem(item),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
