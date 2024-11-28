import 'food_item.dart';

class OrderPlan {
  final int? id;
  final String date;
  final double targetCost;
  final List<FoodItem> items;

  OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.items,
  });

  // Convert an OrderPlan object to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'target_cost': targetCost,
    };
  }

  // Add a factory constructor to create an OrderPlan from a map
  factory OrderPlan.fromMap(Map<String, dynamic> map, [List<FoodItem>? items]) {
    return OrderPlan(
      id: map['id'],
      date: map['date'],
      targetCost: map['target_cost'],
      items: items ?? [],
    );
  }
}
