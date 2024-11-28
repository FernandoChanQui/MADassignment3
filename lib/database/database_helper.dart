import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_order.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        target_cost REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_plan_items(
        order_plan_id INTEGER,
        food_item_id INTEGER,
        FOREIGN KEY (order_plan_id) REFERENCES order_plans (id),
        FOREIGN KEY (food_item_id) REFERENCES food_items (id)
      )
    ''');

    await _insertInitialFoodItems(db);
  }

  Future<void> _insertInitialFoodItems(Database db) async {
    final initialFoodItems = [
      {'name': 'Pizza', 'cost': 12.99},
      {'name': 'Burger', 'cost': 8.99},
      {'name': 'Salad', 'cost': 7.99},
      {'name': 'Pasta', 'cost': 11.99},
      {'name': 'Sushi Roll', 'cost': 14.99},
      {'name': 'Chicken Rice', 'cost': 9.99},
      {'name': 'Fish & Chips', 'cost': 13.99},
      {'name': 'Steak', 'cost': 24.99},
      {'name': 'Sandwich', 'cost': 6.99},
      {'name': 'Soup', 'cost': 5.99},
      {'name': 'Noodles', 'cost': 10.99},
      {'name': 'Taco', 'cost': 7.99},
      {'name': 'Burrito', 'cost': 9.99},
      {'name': 'Fried Rice', 'cost': 8.99},
      {'name': 'Curry', 'cost': 12.99},
      {'name': 'Pad Thai', 'cost': 11.99},
      {'name': 'Dumplings', 'cost': 8.99},
      {'name': 'Ramen', 'cost': 13.99},
      {'name': 'Poke Bowl', 'cost': 15.99},
      {'name': 'Caesar Salad', 'cost': 9.99},
    ];

    for (var item in initialFoodItems) {
      await db.insert('food_items', item);
    }
  }

  
  Future<int> insertFoodItem(FoodItem item) async {
    final db = await database;
    return await db.insert('food_items', item.toMap());
  }

  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('food_items');
    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  Future<int> updateFoodItem(FoodItem item) async {
    final db = await database;
    return await db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteFoodItem(int id) async {
    final db = await database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOrderPlan(OrderPlan order) async {
  final db = await database;
  
  // First, find the existing order plan's ID
  final existingPlanMaps = await db.query(
    'order_plans',
    where: 'date = ?',
    whereArgs: [order.date],
  );

  if (existingPlanMaps.isEmpty) {
    // If no existing plan, insert a new one
    await insertOrderPlan(order);
  }

  final existingPlanId = existingPlanMaps.first['id'] as int;

  // Update the order plan's target cost
  await db.update(
    'order_plans',
    {'target_cost': order.targetCost},
    where: 'id = ?',
    whereArgs: [existingPlanId],
  );

  // Delete existing order plan items
  await db.delete(
    'order_plan_items',
    where: 'order_plan_id = ?',
    whereArgs: [existingPlanId],
  );

  // Insert new order plan items
  for (var item in order.items) {
    await db.insert('order_plan_items', {
      'order_plan_id': existingPlanId,
      'food_item_id': item.id,
    });
  }
}

Future<void> deleteOrderPlan(String date) async {
  final db = await database;
  await db.delete(
    'order_plans',
    where: 'date = ?',
    whereArgs: [date],
  );
}


  // Order plan operations
  Future<int> insertOrderPlan(OrderPlan plan) async {
    final db = await database;
    final id = await db.insert('order_plans', plan.toMap());
    
    for (var item in plan.items) {
      await db.insert('order_plan_items', {
        'order_plan_id': id,
        'food_item_id': item.id,
      });
    }
    return id;
  }

  Future<OrderPlan?> getOrderPlanByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> planMaps = await db.query(
      'order_plans',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (planMaps.isEmpty) return null;

    final plan = OrderPlan.fromMap(planMaps.first);
    final List<Map<String, dynamic>> itemMaps = await db.rawQuery('''
      SELECT f.* FROM food_items f
      INNER JOIN order_plan_items opi ON f.id = opi.food_item_id
      WHERE opi.order_plan_id = ?
    ''', [plan.id]);

    return OrderPlan(
      id: plan.id,
      date: plan.date,
      targetCost: plan.targetCost,
      items: itemMaps.map((map) => FoodItem.fromMap(map)).toList(),
    );
  }
  

  Future<List<OrderPlan>> getAllOrderPlans() async {
  final db = await database;

  // Query the order_plans table
  final List<Map<String, dynamic>> orderPlanMaps = await db.query('order_plans');

  List<OrderPlan> orderPlans = [];
  for (var planMap in orderPlanMaps) {
    // Query the order_plan_items table to get food_item_ids for the current order plan
    final List<Map<String, dynamic>> orderPlanItemMaps = await db.query(
      'order_plan_items',
      where: 'order_plan_id = ?',
      whereArgs: [planMap['id']],
    );

    // Extract the food_item_ids from the result
    final foodItemIds = orderPlanItemMaps.map((e) => e['food_item_id']).toList();

    // Query the food_items table to get food items for the current order plan
    final List<Map<String, dynamic>> foodItemMaps = await db.query(
      'food_items',
      where: 'id IN (${List.filled(foodItemIds.length, '?').join(',')})',
      whereArgs: foodItemIds,
    );

    // Convert the food items to FoodItem objects
    List<FoodItem> foodItems = foodItemMaps.map((foodMap) => FoodItem.fromMap(foodMap)).toList();

    // Add the OrderPlan object with its associated food items
    orderPlans.add(OrderPlan.fromMap(planMap, foodItems));
  }

  return orderPlans;
}



}