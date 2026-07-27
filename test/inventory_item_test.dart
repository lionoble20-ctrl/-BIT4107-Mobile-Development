import 'package:flutter_test/flutter_test.dart';
import 'package:retailapp/models/inventory_item.dart';

void main() {
  group('InventoryItem calculations', () {
    test('profitMarginPercent calculates correctly for a normal item', () {
      final item = InventoryItem(
        id: 'test1',
        name: 'Test Blouse',
        category: 'Clothing',
        costPrice: 100,
        sellingPrice: 150,
        stockQty: 20,
        dateAdded: DateTime.now(),
      );

      // Expected: ((150 - 100) / 100) * 100 = 50%
      expect(item.profitMarginPercent, 50);
    });

    test('isLowStock returns true when stock is between 1 and 10', () {
      final item = InventoryItem(
        id: 'test2',
        name: 'Test Sweater',
        category: 'Clothing',
        costPrice: 80,
        sellingPrice: 120,
        stockQty: 5,
        dateAdded: DateTime.now(),
      );

      expect(item.isLowStock, true);
      expect(item.isOutOfStock, false);
    });

    test('breakevenUnits calculates correctly when margin is positive', () {
      final item = InventoryItem(
        id: 'test3',
        name: 'Test Jacket',
        category: 'Clothing',
        costPrice: 200,
        sellingPrice: 250,
        stockQty: 10,
        dateAdded: DateTime.now(),
      );

      // profitMargin = 50, breakevenUnits = ceil(200 / 50) = 4
      expect(item.breakevenUnits, 4);
    });
  });
}
