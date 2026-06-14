class Product {
  final String id;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  int stockQty;
  int unitsSold;
  final String unit;
  final DateTime dateAdded;
  DateTime? lastSaleDate;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQty,
    this.unitsSold = 0,
    this.unit = 'pcs',
    required this.dateAdded,
    this.lastSaleDate,
  });

  double get profitMargin => sellingPrice - costPrice;
  double get profitMarginPercent =>
      costPrice == 0 ? 0 : ((sellingPrice - costPrice) / costPrice) * 100;
  double get totalProfitGenerated => profitMargin * unitsSold;
  double get totalLossIncurred => stockQty * costPrice;
  double get turnoverRate =>
      unitsSold / (stockQty + unitsSold == 0 ? 1 : stockQty + unitsSold);
  double get expectedTotalRevenue => sellingPrice * stockQty;
  double get expectedTotalProfit => profitMargin * stockQty;
  double get breakevenPoint =>
      sellingPrice == costPrice ? 0 : costPrice / (sellingPrice - costPrice);

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      costPrice: map['costPrice'],
      sellingPrice: map['sellingPrice'],
      stockQty: map['stockQty'],
      unitsSold: map['unitsSold'] ?? 0,
      unit: map['unit'] ?? 'pcs',
      dateAdded: DateTime.parse(map['dateAdded']),
      lastSaleDate: map['lastSaleDate'] != null
          ? DateTime.parse(map['lastSaleDate'])
          : null,
    );
  }

  Product copyWith({
    String? name,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? stockQty,
    int? unitsSold,
    String? unit,
    DateTime? lastSaleDate,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQty: stockQty ?? this.stockQty,
      unitsSold: unitsSold ?? this.unitsSold,
      unit: unit ?? this.unit,
      dateAdded: dateAdded,
      lastSaleDate: lastSaleDate ?? this.lastSaleDate,
    );
  }
}

class Sale {
  final String id;
  final String productId;
  final int quantitySold;
  final DateTime saleDate;
  final double totalRevenue;
  final double totalCost;
  final double profit;

  Sale({
    required this.id,
    required this.productId,
    required this.quantitySold,
    required this.saleDate,
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantitySold': quantitySold,
      'saleDate': saleDate.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'profit': profit,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['productId'],
      quantitySold: map['quantitySold'],
      saleDate: DateTime.parse(map['saleDate']),
      totalRevenue: map['totalRevenue'],
      totalCost: map['totalCost'],
      profit: map['profit'],
    );
  }
}

class BusinessSettings {
  final int id;
  final String businessName;
  final String currency;
  final int stockLowThreshold;
  final bool setupComplete;

  BusinessSettings({
    this.id = 1,
    required this.businessName,
    this.currency = 'KES',
    this.stockLowThreshold = 10,
    this.setupComplete = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'currency': currency,
      'stockLowThreshold': stockLowThreshold,
      'setupComplete': setupComplete ? 1 : 0,
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      id: map['id'],
      businessName: map['businessName'],
      currency: map['currency'],
      stockLowThreshold: map['stockLowThreshold'],
      setupComplete: map['setupComplete'] == 1,
    );
  }

  BusinessSettings copyWith({
    String? businessName,
    String? currency,
    int? stockLowThreshold,
    bool? setupComplete,
  }) {
    return BusinessSettings(
      id: id,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      stockLowThreshold: stockLowThreshold ?? this.stockLowThreshold,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }
}
