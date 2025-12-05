import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY';
    const textType = 'TEXT';
    const realType = 'REAL';
    const intType = 'INTEGER';

    // Products Table
    await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType NOT NULL,
  sku $textType NOT NULL,
  price $realType NOT NULL,
  image_url $textType,
  category_id $intType
)
''');

    // Orders Table (Offline Storage)
    await db.execute('''
CREATE TABLE orders (
  local_id $idType AUTOINCREMENT,
  customer_id $intType,
  final_total $realType,
  status $textType,
  created_at $textType,
  is_synced $intType DEFAULT 0
)
''');

    // Order Items Table
    await db.execute('''
CREATE TABLE order_items (
  id $idType AUTOINCREMENT,
  order_local_id $intType,
  product_id $intType,
  quantity $intType,
  unit_price $realType,
  FOREIGN KEY (order_local_id) REFERENCES orders (local_id) ON DELETE CASCADE
)
''');
  }

  // Product Operations
  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProducts(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var product in products) {
      batch.insert('products', product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<void> clearProducts() async {
    final db = await instance.database;
    await db.delete('products');
  }

  // Order Operations
  Future<int> createOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    int orderId = await db.insert('orders', orderData);
    
    final batch = db.batch();
    for (var item in items) {
      item['order_local_id'] = orderId;
      batch.insert('order_items', item);
    }
    await batch.commit(noResult: true);
    return orderId;
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await instance.database;
    return await db.query('orders', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderLocalId) async {
    final db = await instance.database;
    return await db.query('order_items', where: 'order_local_id = ?', whereArgs: [orderLocalId]);
  }

  Future<void> markOrderAsSynced(int localId) async {
    final db = await instance.database;
    await db.update('orders', {'is_synced': 1}, where: 'local_id = ?', whereArgs: [localId]);
  }
}
