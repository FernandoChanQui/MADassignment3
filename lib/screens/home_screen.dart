import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../database/database_helper.dart';
import 'all_orders_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _targetCostController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<FoodItem> _availableFoodItems = [];
  Map<FoodItem, int> _selectedFoodItems = {}; 
  double _targetCost = 50.0;

  @override
  void initState() {
    super.initState();
    _targetCostController.text = _targetCost.toStringAsFixed(2);
    _loadFoodItems();
    _loadOrderPlan();
  }

  Future<void> _loadFoodItems() async {
    final items = await _dbHelper.getAllFoodItems();
    setState(() {
      _availableFoodItems = items;
    });
  }

  Future<void> _loadOrderPlan() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final orderPlan = await _dbHelper.getOrderPlanByDate(dateStr);
    setState(() {
      _selectedFoodItems.clear(); // Clear existing items
      
      if (orderPlan != null) {
        // Safely convert items to quantity map
        final List<FoodItem> itemsList = orderPlan.items.cast<FoodItem>();
        
        for (var item in itemsList) {
          _selectedFoodItems[item] = (_selectedFoodItems[item] ?? 0) + 1;
        }
      }
    });
  }

   double _calculateTotalCost() {
    return _selectedFoodItems.entries.fold(0, (sum, entry) => sum + (entry.key.cost * entry.value));
  }

  void _addFoodItem(FoodItem item) {
    final currentQuantity = _selectedFoodItems[item] ?? 0;
    final totalCost = _calculateTotalCost() + item.cost;
    
    if (totalCost <= _targetCost) {
      setState(() {
        _selectedFoodItems[item] = currentQuantity + 1;
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
      final currentQuantity = _selectedFoodItems[item] ?? 0;
      if (currentQuantity > 1) {
        _selectedFoodItems[item] = currentQuantity - 1;
      } else {
        _selectedFoodItems.remove(item);
      }
    });
  }

  Future<void> _saveOrderPlan() async {
    if (_selectedFoodItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select some food items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert the Map to a list of items for OrderPlan
    final itemsList = _selectedFoodItems.entries.expand((entry) => List.filled(entry.value, entry.key)).toList();

    final orderPlan = OrderPlan(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      targetCost: _targetCost,
      items: itemsList,
    );

    await _dbHelper.insertOrderPlan(orderPlan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order plan saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _viewAllOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllOrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Order App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _viewAllOrders,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2025),
                            );
                            if (picked != null && picked != _selectedDate) {
                              setState(() {
                                _selectedDate = picked;
                                _selectedFoodItems = {};
                              });
                              _loadOrderPlan();
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFoodList(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSelectedItems(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return Card(
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
    );
  }

  Widget _buildSelectedItems() {
    return Card(
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
              itemCount: _selectedFoodItems.length,
              itemBuilder: (context, index) {
                final item = _selectedFoodItems.keys.elementAt(index);
                final quantity = _selectedFoodItems[item]!;
                return ListTile(
                  title: Text('${item.name} (x$quantity)'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total Cost: \$${_calculateTotalCost().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveOrderPlan,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Order Plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}