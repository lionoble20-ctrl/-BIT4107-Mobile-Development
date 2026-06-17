import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/inventory_item.dart';

// Mobile imports
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path_helper;

// Web imports
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast_web/sembast_web.dart' as sembast_web;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Mobile database
  static sqflite.Database? _mobileDb;

  // Web database
  static sembast.Database? _webDb;

  // Web stores (equivalent to tables)
  final _productsStore = sembast.stringMapStoreFactory.store('products');
  final _salesStore = sembast.stringMapStoreFactory.store('sales');
  final _settingsStore = sembast.stringMapStoreFactory.store('settings');
  final _usersStore = sembast.stringMapStoreFactory.store('users');

  DatabaseHelper._init();

  // ── INIT ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb) {
      await _initWeb();
    } else {
      await _initMobile();
    }
  }

  Future<void> _initWeb() async {
    if (_webDb != null) return;
    _webDb = await sembast_web.databaseFactoryWeb.openDatabase(
      'retail_engine.db',
    );
  }

  Future<void> _initMobile() async {
    if (_mobileDb != null) return;
    final dbPath = await sqflite.getDatabasesPath();
    final fullPath = path_helper.join(dbPath, 'retail_engine.db');
    _mobileDb = await sqflite.openDatabase(
      fullPath,
      version: 2,
      onCreate: _createMobileDB,
      onUpgrade: _upgradeMobileDB,
    );
  }

  Future<void> _createMobileDB(sqflite.Database db, int version) async {
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

    await _createUsersTable(db);
  }

  Future<void> _upgradeMobileDB(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
  }

  Future<void> _createUsersTable(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        email TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL,
        businessName TEXT,
        phone TEXT,
        dateCreated TEXT NOT NULL
      )
    ''');
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  Future<sqflite.Database> get _mobile async {
    if (_mobileDb == null) await _initMobile();
    return _mobileDb!;
  }

  Future<sembast.Database> get _web async {
    if (_webDb == null) await _initWeb();
    return _webDb!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insertProduct(InventoryItem item) async {
    if (kIsWeb) {
      await _productsStore
          .record(item.id)
          .put(await _web, item.toMap().cast<String, Object?>());
    } else {
      final db = await _mobile;
      await db.insert(
        'products',
        item.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateProduct(InventoryItem item) async {
    if (kIsWeb) {
      await _productsStore
          .record(item.id)
          .put(await _web, item.toMap().cast<String, Object?>());
    } else {
      final db = await _mobile;
      await db.update(
        'products',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
  }

  Future<void> deleteProduct(String id) async {
    if (kIsWeb) {
      await _productsStore.record(id).delete(await _web);
    } else {
      final db = await _mobile;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<InventoryItem>> getAllProducts() async {
    if (kIsWeb) {
      final snapshots = await _productsStore.find(
        await _web,
        finder: sembast.Finder(
          sortOrders: [sembast.SortOrder('dateAdded', false)],
        ),
      );
      return snapshots
          .map((s) => InventoryItem.fromMap(Map<String, dynamic>.from(s.value)))
          .toList();
    } else {
      final db = await _mobile;
      final maps = await db.query('products', orderBy: 'dateAdded DESC');
      return maps.map((m) => InventoryItem.fromMap(m)).toList();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SALES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insertSale(SaleRecord sale) async {
    if (kIsWeb) {
      await _salesStore
          .record(sale.id)
          .put(await _web, sale.toMap().cast<String, Object?>());
    } else {
      final db = await _mobile;
      await db.insert(
        'sales',
        sale.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<SaleRecord>> getAllSales() async {
    if (kIsWeb) {
      final snapshots = await _salesStore.find(
        await _web,
        finder: sembast.Finder(
          sortOrders: [sembast.SortOrder('saleDate', false)],
        ),
      );
      return snapshots
          .map((s) => SaleRecord.fromMap(Map<String, dynamic>.from(s.value)))
          .toList();
    } else {
      final db = await _mobile;
      final maps = await db.query('sales', orderBy: 'saleDate DESC');
      return maps.map((m) => SaleRecord.fromMap(m)).toList();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveSetting(String key, String value) async {
    if (kIsWeb) {
      await _settingsStore.record(key).put(await _web, {
        'key': key,
        'value': value,
      });
    } else {
      final db = await _mobile;
      await db.insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    }
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      final record = await _settingsStore.record(key).get(await _web);
      if (record == null) return null;
      return record['value'] as String?;
    } else {
      final db = await _mobile;
      final maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isEmpty) return null;
      return maps.first['value'] as String?;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERS — NEW
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> insertUser({
    required String email,
    required String fullName,
    required String passwordHash,
    required String role,
    String? businessName,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await getUserByEmail(normalizedEmail);
    if (existing != null) return false;

    final userMap = {
      'email': normalizedEmail,
      'fullName': fullName,
      'passwordHash': passwordHash,
      'role': role,
      'businessName': businessName ?? '',
      'phone': phone ?? '',
      'dateCreated': DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      await _usersStore
          .record(normalizedEmail)
          .put(await _web, userMap.cast<String, Object?>());
    } else {
      final db = await _mobile;
      await db.insert(
        'users',
        userMap,
        conflictAlgorithm: sqflite.ConflictAlgorithm.fail,
      );
    }
    return true;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      final record = await _usersStore.record(normalizedEmail).get(await _web);
      if (record == null) return null;
      return Map<String, dynamic>.from(record);
    } else {
      final db = await _mobile;
      final maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );
      if (maps.isEmpty) return null;
      return maps.first;
    }
  }

  Future<void> updateUser({
    required String email,
    required String fullName,
    String? businessName,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await getUserByEmail(normalizedEmail);
    if (existing == null) return;

    final updated = {
      ...existing,
      'fullName': fullName,
      'businessName': businessName ?? existing['businessName'],
      'phone': phone ?? existing['phone'],
    };

    if (kIsWeb) {
      await _usersStore
          .record(normalizedEmail)
          .put(await _web, updated.cast<String, Object?>());
    } else {
      final db = await _mobile;
      await db.update(
        'users',
        {
          'fullName': updated['fullName'],
          'businessName': updated['businessName'],
          'phone': updated['phone'],
        },
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );
    }
  }
}
