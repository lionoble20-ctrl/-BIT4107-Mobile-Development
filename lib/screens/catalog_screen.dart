import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final currency = globalSettings.currency;
    final categories = [
      'All',
      ...{...globalInventory.map((i) => i.category)},
    ];

    final filtered = globalInventory.where((item) {
      final matchSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat =
          _filterCategory == 'All' || item.category == _filterCategory;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Market Catalog',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${globalSettings.businessName} • ${globalInventory.length} products',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search products or categories...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: const Color(0xFF1E293B),
              ),
            ),
          ),
          // Category filter chips
          if (categories.length > 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final selected = _filterCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _filterCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.grey,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Grid
          Expanded(
            child: filtered.isEmpty
                ? _emptyState(globalInventory.isEmpty)
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ProductCard(
                      item: filtered[i],
                      currency: currency,
                      onUpdate: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty
                ? 'No products yet.\nGo to Stock Entry to add your first product.'
                : 'No products match your search.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final InventoryItem item;
  final String currency;
  final VoidCallback onUpdate;

  const _ProductCard({
    required this.item,
    required this.currency,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    if (item.isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
    } else if (item.isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
    } else {
      statusColor = const Color(0xFF22C55E);
      statusText = 'In Stock';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.category,
                style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '$currency ${NumberFormat('#,##0').format(item.sellingPrice)}',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.stockQty} ${item.unit}',
              style: TextStyle(
                color: item.isLowStock ? Colors.orange : Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isOutOfStock
                      ? Colors.grey[800]
                      : const Color(0xFF22C55E),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                ),
                onPressed: item.isOutOfStock
                    ? null
                    : () => _showSaleDialog(context),
                child: const Text(
                  'SIMULATE SALE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDialog(BuildContext context) {
    int qty = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Sell ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: ${item.stockQty} ${item.unit}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        setS(() => qty = (qty - 1).clamp(1, item.stockQty)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setS(() => qty = (qty + 1).clamp(1, item.stockQty)),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              Text(
                'Revenue: $currency ${NumberFormat('#,##0.00').format(item.sellingPrice * qty)}',
                style: const TextStyle(color: Color(0xFF22C55E)),
              ),
              Text(
                'Profit: $currency ${NumberFormat('#,##0.00').format(item.profitMargin * qty)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                recordSale(item, qty);
                onUpdate();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sale recorded: $qty ${item.unit} of ${item.name}',
                    ),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              },
              child: const Text('Confirm Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
