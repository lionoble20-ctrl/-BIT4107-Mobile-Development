import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retailapp/api_config.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../services/payment_service.dart';
import '../services/input_handler_service.dart';
import '../services/gesture_service.dart';
import 'profile_screen.dart';
import 'logs_screen.dart';
import 'device_features_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 26),
            tooltip: 'Device Features',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceFeaturesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 26),
            tooltip: 'View Event Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Operator Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => InputHandlerService.handleCatalogSearchInput(
                query: v,
                onSearch: (q) => setState(() => _searchQuery = q),
              ),
              decoration: const InputDecoration(
                hintText: 'Search products or categories...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: Color(0xFF1E293B),
              ),
            ),
          ),
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

class _ProductCard extends StatefulWidget {
  final InventoryItem item;
  final String currency;
  final VoidCallback onUpdate;

  const _ProductCard({
    required this.item,
    required this.currency,
    required this.onUpdate,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  String _usdPrice = '';

  @override
  void initState() {
    super.initState();
    _loadUsdPrice();
  }

  Future<void> _loadUsdPrice() async {
    final converted = await CurrencyService.kesToUSD(widget.item.sellingPrice);
    if (mounted) {
      setState(() => _usdPrice = 'USD ${converted.toStringAsFixed(2)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    if (widget.item.isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
    } else if (widget.item.isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
    } else {
      statusColor = const Color(0xFF22C55E);
      statusText = 'In Stock';
    }

    return GestureDetector(
      onLongPress: () => GestureService.onProductLongPress(
        productName: widget.item.name,
        onAction: () => _showQuickView(context),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.item.category,
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.currency} ${NumberFormat('#,##0').format(widget.item.sellingPrice)}',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (_usdPrice.isNotEmpty)
                Text(
                  _usdPrice,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                '${widget.item.stockQty} ${widget.item.unit}',
                style: TextStyle(
                  color: widget.item.isLowStock ? Colors.orange : Colors.grey,
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
                    backgroundColor: widget.item.isOutOfStock
                        ? Colors.grey[800]
                        : const Color(0xFF22C55E),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: widget.item.isOutOfStock
                      ? null
                      : () => GestureService.onProductTap(
                          productName: widget.item.name,
                          onAction: () => _showSaleDialog(context),
                        ),
                  child: const Text(
                    'SELL VIA M-PESA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickView(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(widget.item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${widget.item.category}'),
            Text('Stock: ${widget.item.stockQty} ${widget.item.unit}'),
            Text('Price: ${widget.currency} ${widget.item.sellingPrice}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSaleDialog(BuildContext context) {
    int qty = 1;
    final phoneController = TextEditingController();
    bool isProcessing = false;
    String? statusMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Sell ${widget.item.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Available: ${widget.item.stockQty} ${widget.item.unit}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: isProcessing
                          ? null
                          : () => setS(
                              () => qty = (qty - 1).clamp(
                                1,
                                widget.item.stockQty,
                              ),
                            ),
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
                      onPressed: isProcessing
                          ? null
                          : () => setS(
                              () => qty = (qty + 1).clamp(
                                1,
                                widget.item.stockQty,
                              ),
                            ),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Revenue: ${widget.currency} ${NumberFormat('#,##0.00').format(widget.item.sellingPrice * qty)}',
                  style: const TextStyle(color: Color(0xFF22C55E)),
                ),
                Text(
                  'Profit: ${widget.currency} ${NumberFormat('#,##0.00').format(widget.item.profitMargin * qty)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  enabled: !isProcessing,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa phone (e.g. 254712345678)',
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          statusMessage!.toLowerCase().contains('fail') ||
                              statusMessage!.toLowerCase().contains('error') ||
                              statusMessage!.toLowerCase().contains('timed out')
                          ? Colors.redAccent
                          : const Color(0xFF22C55E),
                    ),
                  ),
                ],
                if (isProcessing) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(color: Color(0xFF22C55E)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final phone = phoneController.text.trim();
                      if (phone.length < 10) {
                        setS(
                          () => statusMessage = 'Enter a valid phone number',
                        );
                        return;
                      }
                      setS(() {
                        isProcessing = true;
                        statusMessage = 'Sending M-Pesa prompt...';
                      });
                      try {
                        final invoiceId = await PaymentService.initiateMpesaPayment(
                          phoneNumber: phone,
                          amount: widget.item.sellingPrice * qty,
                          customerEmail:
                              currentUserSession?['email'] ??
                              'customer@sifa.co.ke',
                          apiRef:
                              'SALE-${widget.item.id}-${DateTime.now().millisecondsSinceEpoch}',
                        );
                        setS(
                          () => statusMessage =
                              'Check your phone — enter M-Pesa PIN to confirm',
                        );
                        final result = await PaymentService.pollPaymentStatus(
                          invoiceId: invoiceId,
                        );
                        if (result == 'COMPLETE') {
                          final sale = SaleRecord(
                            id: generateId(),
                            productId: widget.item.id,
                            productName: widget.item.name,
                            quantitySold: qty,
                            saleDate: DateTime.now(),
                            totalRevenue: widget.item.sellingPrice * qty,
                            totalCost: widget.item.costPrice * qty,
                            profit: widget.item.profitMargin * qty,
                          );
                          widget.item.stockQty -= qty;
                          widget.item.unitsSold += qty;
                          widget.item.lastSaleDate = DateTime.now();
                          await DatabaseHelper.instance.updateProduct(
                            widget.item,
                          );
                          await DatabaseHelper.instance.insertSale(sale);
                          globalSales.insert(0, sale);
                          widget.onUpdate();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment confirmed — $qty ${widget.item.unit} of ${widget.item.name} sold',
                                ),
                                backgroundColor: const Color(0xFF22C55E),
                              ),
                            );
                          }
                        } else {
                          setS(() {
                            isProcessing = false;
                            statusMessage = result == 'TIMEOUT'
                                ? 'Payment timed out — try again'
                                : 'Payment failed — try again';
                          });
                        }
                      } catch (e) {
                        setS(() {
                          isProcessing = false;
                          statusMessage =
                              'Error: could not reach payment service';
                        });
                      }
                    },
              child: Text(isProcessing ? 'Processing...' : 'Pay with M-Pesa'),
            ),
          ],
        ),
      ),
    );
  }
}
