import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('retail_engine.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        stockQty INTEGER NOT NULL,
        unitsSold INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'units',
        dateAdded TEXT NOT NULL,
        lastSaleDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantitySold INTEGER NOT NULL,
        saleDate TEXT NOT NULL,
        totalRevenue REAL NOT NULL,
        totalCost REAL NOT NULL,
        profit REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── PRODUCTS ──────────────────────────────────────────────────────────────

  Future<void> saveAllProducts() async {
    final db = await database;
    final batch = db.batch();
    for (var item in globalInventory) {
      batch.insert(
        'products',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveProduct(InventoryItem item) async {
    final db = await database;
    await db.insert(
      'products',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InventoryItem>> loadProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'dateAdded DESC');
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  // ── SALES ─────────────────────────────────────────────────────────────────

  Future<void> saveSale(SaleRecord sale) async {
    final db = await database;
    await db.insert(
      'sales',
      sale.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SaleRecord>> loadSales() async {
    final db = await database;
    final maps = await db.query('sales', orderBy: 'saleDate DESC');
    return maps.map((m) => SaleRecord.fromMap(m)).toList();
  }

  // ── SETTINGS ──────────────────────────────────────────────────────────────

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }
}
