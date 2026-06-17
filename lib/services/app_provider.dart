import 'package:flutter/foundation.dart';
import 'package:retailapp/api_config.dart';
import '../models/inventory_item.dart';
import 'database_helper.dart';

class AppDataService {
  static final AppDataService instance = AppDataService._init();
  AppDataService._init();

  final _db = DatabaseHelper.instance;

  // ── LOAD ALL DATA ON STARTUP ──────────────────────────────────────────────

  Future<void> loadAllData() async {
    try {
      // Load products
      final products = await _db.getAllProducts();
      globalInventory.clear();
      globalInventory.addAll(products);

      // Load sales
      final sales = await _db.getAllSales();
      globalSales.clear();
      globalSales.addAll(sales);

      // Load settings
      final businessName = await _db.getSetting('businessName') ?? '';
      final businessType = await _db.getSetting('businessType') ?? '';
      final currency = await _db.getSetting('currency') ?? 'KES';
      final setupComplete = await _db.getSetting('setupComplete') ?? 'false';

      globalSettings.businessName = businessName;
      globalSettings.businessType = businessType;
      globalSettings.currency = currency;
      globalSettings.setupComplete = setupComplete == 'true';

      debugPrint(
        'Data loaded: ${globalInventory.length} products, ${globalSales.length} sales',
      );
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  // ── PRODUCTS ──────────────────────────────────────────────────────────────

  Future<void> saveProduct(InventoryItem item) async {
    try {
      await _db.insertProduct(item);
    } catch (e) {
      debugPrint('Error saving product: $e');
    }
  }

  Future<void> updateProduct(InventoryItem item) async {
    try {
      await _db.updateProduct(item);
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _db.deleteProduct(id);
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
  }

  // ── SALES ─────────────────────────────────────────────────────────────────

  Future<void> saveSale(SaleRecord sale) async {
    try {
      await _db.insertSale(sale);
    } catch (e) {
      debugPrint('Error saving sale: $e');
    }
  }

  // ── SETTINGS ──────────────────────────────────────────────────────────────

  Future<void> saveSettings({
    required String businessName,
    required String businessType,
    required String currency,
  }) async {
    try {
      await _db.saveSetting('businessName', businessName);
      await _db.saveSetting('businessType', businessType);
      await _db.saveSetting('currency', currency);
      await _db.saveSetting('setupComplete', 'true');

      globalSettings.businessName = businessName;
      globalSettings.businessType = businessType;
      globalSettings.currency = currency;
      globalSettings.setupComplete = true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}
