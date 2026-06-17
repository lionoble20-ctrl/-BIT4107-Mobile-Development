import 'package:retailapp/api_config.dart';
// Use the shared globalSettings; do NOT redeclare it here.

// Global state — shared across all screens
List<InventoryItem> globalInventory = [];
List<SaleRecord> globalSales = [];

String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

// ── BUSINESS SETTINGS ─────────────────────────────────────────────────────────

class BusinessSettings {
  String businessName;
  String businessType;
  String currency;
  bool setupComplete;

  BusinessSettings({
    this.businessName = '',
    this.businessType = '',
    this.currency = 'KES',
    this.setupComplete = false,
  });
}

// ── INVENTORY ITEM ────────────────────────────────────────────────────────────

class InventoryItem {
  final String id;
  String name;
  String category;
  double costPrice;
  double sellingPrice;
  int stockQty;
  int unitsSold;
  String unit;
  final DateTime dateAdded;
  DateTime? lastSaleDate;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQty,
    this.unitsSold = 0,
    this.unit = 'units',
    required this.dateAdded,
    this.lastSaleDate,
  });

  // ── Calculated getters ────────────────────────────────────────────────────

  double get profitMargin => sellingPrice - costPrice;

  double get profitMarginPercent =>
      costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  double get totalProfitGenerated => profitMargin * unitsSold;

  double get totalRevenueGenerated => sellingPrice * unitsSold;

  double get totalCostIncurred => costPrice * unitsSold;

  double get stockHoldingValue => stockQty * costPrice;

  double get expectedRevenue => sellingPrice * stockQty;

  double get expectedProfit => profitMargin * stockQty;

  double get turnoverRate {
    final total = stockQty + unitsSold;
    return total == 0 ? 0 : unitsSold / total;
  }

  int get breakevenUnits =>
      profitMargin > 0 ? (costPrice / profitMargin).ceil() : 0;

  bool get isLowStock => stockQty <= 10 && stockQty > 0;
  bool get isOutOfStock => stockQty == 0;
  bool get isStagnant {
    if (unitsSold == 0) return true;
    if (lastSaleDate == null) return true;
    return DateTime.now().difference(lastSaleDate!).inDays > 7;
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'stockQty': stockQty,
    'unitsSold': unitsSold,
    'unit': unit,
    'dateAdded': dateAdded.toIso8601String(),
    'lastSaleDate': lastSaleDate?.toIso8601String(),
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'],
    name: map['name'],
    category: map['category'],
    costPrice: (map['costPrice'] as num).toDouble(),
    sellingPrice: (map['sellingPrice'] as num).toDouble(),
    stockQty: map['stockQty'],
    unitsSold: map['unitsSold'] ?? 0,
    unit: map['unit'] ?? 'units',
    dateAdded: DateTime.parse(map['dateAdded']),
    lastSaleDate: map['lastSaleDate'] != null
        ? DateTime.parse(map['lastSaleDate'])
        : null,
  );
}

// ── SALE RECORD ───────────────────────────────────────────────────────────────

class SaleRecord {
  final String id;
  final String productId;
  final String productName;
  final int quantitySold;
  final DateTime saleDate;
  final double totalRevenue;
  final double totalCost;
  final double profit;

  SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.saleDate,
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantitySold': quantitySold,
    'saleDate': saleDate.toIso8601String(),
    'totalRevenue': totalRevenue,
    'totalCost': totalCost,
    'profit': profit,
  };

  factory SaleRecord.fromMap(Map<String, dynamic> map) => SaleRecord(
    id: map['id'],
    productId: map['productId'],
    productName: map['productName'],
    quantitySold: map['quantitySold'],
    saleDate: DateTime.parse(map['saleDate']),
    totalRevenue: (map['totalRevenue'] as num).toDouble(),
    totalCost: (map['totalCost'] as num).toDouble(),
    profit: (map['profit'] as num).toDouble(),
  );
}

// ── P&L SUMMARY ───────────────────────────────────────────────────────────────

class PnLSummary {
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double realizedMargin;
  final double stagnantRisk;
  final String bestProduct;
  final String worstProduct;
  final List<String> lossRiskItems;
  final int transactionCount;

  PnLSummary({
    required this.totalRevenue,
    required this.totalCost,
    required this.netProfit,
    required this.realizedMargin,
    required this.stagnantRisk,
    required this.bestProduct,
    required this.worstProduct,
    required this.lossRiskItems,
    required this.transactionCount,
  });

  // Calculate from sales + inventory
  factory PnLSummary.calculate(
    List<SaleRecord> sales,
    List<InventoryItem> inventory,
  ) {
    double totalRevenue = sales.fold(0, (s, r) => s + r.totalRevenue);
    double totalCost = sales.fold(0, (s, r) => s + r.totalCost);
    double netProfit = totalRevenue - totalCost;
    double realizedMargin = totalRevenue > 0
        ? (netProfit / totalRevenue) * 100
        : 0;

    double stagnantRisk = inventory
        .where((i) => i.isStagnant && i.stockQty > 0)
        .fold(0.0, (s, i) => s + i.stockHoldingValue);

    String bestProduct = 'N/A';
    String worstProduct = 'N/A';
    if (inventory.isNotEmpty) {
      final sorted = List<InventoryItem>.from(inventory)
        ..sort(
          (a, b) => b.totalProfitGenerated.compareTo(a.totalProfitGenerated),
        );
      bestProduct = sorted.first.name;
      worstProduct = sorted.last.name;
    }

    List<String> lossRiskItems = inventory
        .where(
          (i) =>
              i.stockHoldingValue > 0 &&
              i.totalProfitGenerated < i.stockHoldingValue * 0.1,
        )
        .map((i) => i.name)
        .toList();

    return PnLSummary(
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      netProfit: netProfit,
      realizedMargin: realizedMargin,
      stagnantRisk: stagnantRisk,
      bestProduct: bestProduct,
      worstProduct: worstProduct,
      lossRiskItems: lossRiskItems,
      transactionCount: sales.length,
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

List<SaleRecord> getSalesByPeriod(String period) {
  final now = DateTime.now();
  DateTime from;
  switch (period) {
    case 'Daily':
      from = DateTime(now.year, now.month, now.day);
      break;
    case 'Weekly':
      from = now.subtract(const Duration(days: 7));
      break;
    case 'Monthly':
      from = DateTime(now.year, now.month, 1);
      break;
    case 'Yearly':
      from = DateTime(now.year, 1, 1);
      break;
    default:
      from = DateTime(2000);
  }
  return globalSales.where((s) => s.saleDate.isAfter(from)).toList();
}

void recordSale(InventoryItem item, int qty) {
  item.stockQty -= qty;
  item.unitsSold += qty;
  item.lastSaleDate = DateTime.now();

  globalSales.insert(
    0,
    SaleRecord(
      id: generateId(),
      productId: item.id,
      productName: item.name,
      quantitySold: qty,
      saleDate: DateTime.now(),
      totalRevenue: item.sellingPrice * qty,
      totalCost: item.costPrice * qty,
      profit: item.profitMargin * qty,
    ),
  );
}

// ── ADVISORY ENGINE ───────────────────────────────────────────────────────────

List<Map<String, dynamic>> generateAdvisory() {
  List<Map<String, dynamic>> suggestions = [];
  final currency = globalSettings.currency;

  for (var item in globalInventory) {
    if (item.turnoverRate > 0.6 && item.stockQty < 15) {
      suggestions.add({
        'type': 'scale_up',
        'confidence': 'HIGH',
        'color': 'green',
        'title': 'Restock "${item.name}" urgently',
        'message':
            '"${item.name}" has a ${(item.turnoverRate * 100).toStringAsFixed(0)}% turnover rate with only ${item.stockQty} ${item.unit} remaining. Inject capital immediately to avoid stockout.',
        'extra':
            '+$currency ${(item.profitMargin * 30).toStringAsFixed(0)} projected monthly profit if restocked',
      });
    }

    if (item.isStagnant && item.stockQty > 10) {
      suggestions.add({
        'type': 'risk',
        'confidence': 'HIGH',
        'color': 'orange',
        'title': '"${item.name}" is a holding risk',
        'message':
            '$currency ${item.stockHoldingValue.toStringAsFixed(0)} tied up in "${item.name}" with no recent sales. Capital is not generating returns.',
        'extra':
            'Consider a ${item.profitMarginPercent > 30 ? "15%" : "10%"} markdown to liquidate stock.',
      });
    }

    if (item.profitMarginPercent < 10 && item.unitsSold > 0) {
      suggestions.add({
        'type': 'margin',
        'confidence': 'MEDIUM',
        'color': 'blue',
        'title': 'Low margin on "${item.name}"',
        'message':
            '"${item.name}" is generating only ${item.profitMarginPercent.toStringAsFixed(1)}% margin. Review cost price or adjust selling price.',
        'extra':
            'Increase price by $currency ${(item.costPrice * 0.15).toStringAsFixed(0)} to reach 15%+ margin.',
      });
    }

    if (item.isOutOfStock && item.unitsSold > 5) {
      suggestions.add({
        'type': 'restock',
        'confidence': 'HIGH',
        'color': 'red',
        'title': '"${item.name}" is OUT OF STOCK',
        'message':
            'You have sold ${item.unitsSold} units but stock is now 0. You are losing revenue every day.',
        'extra':
            'Restock at least ${(item.unitsSold / 2).ceil()} units based on your sales history.',
      });
    }
  }

  final monthlySales = getSalesByPeriod('Monthly');
  final pnl = PnLSummary.calculate(monthlySales, globalInventory);
  if (pnl.netProfit < 0) {
    suggestions.insert(0, {
      'type': 'critical',
      'confidence': 'HIGH',
      'color': 'red',
      'title': 'Business is at a LOSS this month',
      'message':
          'Losses of $currency ${pnl.netProfit.abs().toStringAsFixed(0)} recorded. Immediate cost review required.',
      'extra':
          'Focus on high-margin products and reduce slow-mover investment.',
    });
  }

  if (suggestions.isEmpty) {
    suggestions.add({
      'type': 'healthy',
      'confidence': 'HIGH',
      'color': 'green',
      'title': 'Business is performing well',
      'message':
          'No critical risks detected. Keep monitoring your inventory regularly.',
      'extra': 'Add more products to grow your catalog and revenue.',
    });
  }

  return suggestions;
}

String answerQuestion(String question) {
  final q = question.toLowerCase();
  final currency = globalSettings.currency;
  final monthlySales = getSalesByPeriod('Monthly');
  final pnl = PnLSummary.calculate(monthlySales, globalInventory);

  if (q.contains('profit') || q.contains('making money')) {
    if (pnl.netProfit > 0) {
      return 'Yes! You are making a profit of $currency ${pnl.netProfit.toStringAsFixed(2)} this month with a ${pnl.realizedMargin.toStringAsFixed(1)}% margin.';
    } else {
      return 'You are at a loss of $currency ${pnl.netProfit.abs().toStringAsFixed(2)} this month. Review your slow-moving stock immediately.';
    }
  }

  if (q.contains('restock') || q.contains('order')) {
    final low = globalInventory
        .where((i) => i.isLowStock || i.isOutOfStock)
        .toList();
    if (low.isEmpty) {
      return 'All products have adequate stock levels right now.';
    }
    return 'Products needing restock: ${low.map((i) => i.name).join(', ')}.';
  }

  if (q.contains('best') || q.contains('top')) {
    return 'Your best performing product is: ${pnl.bestProduct} based on total profit generated.';
  }

  if (q.contains('worst') || q.contains('drag') || q.contains('margin')) {
    return 'Your worst performing product is: ${pnl.worstProduct}. Consider reviewing its pricing or discontinuing it.';
  }

  if (q.contains('breakeven')) {
    if (globalInventory.isEmpty) {
      return 'Add products first to calculate breakeven.';
    }
    return 'Breakeven units:\n${globalInventory.map((i) => '${i.name}: ${i.breakevenUnits} units').join('\n')}';
  }

  if (q.contains('risk') || q.contains('loss')) {
    if (pnl.lossRiskItems.isEmpty) {
      return 'No items at immediate loss risk detected.';
    }
    return 'Items at loss risk: ${pnl.lossRiskItems.join(', ')}. High holding costs vs profit.';
  }

  if (q.contains('revenue') || q.contains('sales')) {
    return 'This month: $currency ${pnl.totalRevenue.toStringAsFixed(2)} revenue from ${monthlySales.length} transactions.';
  }

  if (q.contains('stagnant') ||
      q.contains('slow') ||
      q.contains('not selling')) {
    final stagnant = globalInventory
        .where((i) => i.isStagnant && i.stockQty > 0)
        .toList();
    if (stagnant.isEmpty) {
      return 'All products have had recent sales. Great job!';
    }
    return 'Stagnant products (no sales in 7+ days): ${stagnant.map((i) => i.name).join(', ')}. Consider promotions.';
  }

  return 'I can answer questions about: profit, restocking, best/worst products, breakeven, risk, revenue, and stagnant stock.';
}
