import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retailapp/api_config.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inventory_item.dart';
import '../services/database_helper.dart';
import '../services/validator_service.dart';
import '../services/input_handler_service.dart';
import '../services/event_logger_service.dart';
import '../services/gesture_service.dart';
import '../services/gemini_service.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Entry'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF22C55E),
            ),
            onPressed: () => _openForm(context, null),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: globalInventory.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_box_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products added yet',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add any product your business sells',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Product'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: globalInventory.length,
              itemBuilder: (_, i) {
                final item = globalInventory[i];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context, item.name),
                  onDismissed: (_) async {
                    GestureService.onProductSwipe(
                      productName: item.name,
                      direction: 'left',
                      onAction: () {},
                    );
                    await DatabaseHelper.instance.deleteProduct(item.id);
                    setState(() {
                      globalInventory.removeWhere((x) => x.id == item.id);
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} deleted')),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF22C55E).withAlpha(40),
                        child: Text(
                          item.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item.category} • ${globalSettings.currency} ${NumberFormat('#,##0').format(item.sellingPrice)} • ${item.stockQty} ${item.unit}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.profitMarginPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _openForm(context, item),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.black,
        onPressed: () => _openForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Product'),
        content: Text('Delete "$name" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, InventoryItem? existing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(existing: existing)),
    );
    setState(() {});
  }
}

// ── PRODUCT FORM ─────────────────────────────────────────────────────────────

class ProductFormScreen extends StatefulWidget {
  final InventoryItem? existing;
  const ProductFormScreen({super.key, this.existing});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _sellCtrl;
  late TextEditingController _stockCtrl;
  String _unit = 'units';
  bool _isAnalysing = false;
  String? _aiDescription;
  double? _aiConfidence;
  File? _aiImage;

  double _margin = 0;
  double _expectedRevenue = 0;
  double _expectedProfit = 0;

  final ImagePicker _picker = ImagePicker();

  final List<String> _units = [
    'units',
    'kg',
    'g',
    'litres',
    'ml',
    'pieces',
    'boxes',
    'bags',
    'packets',
    'pairs',
    'metres',
    'dozens',
    'plates',
    'bottles',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _costCtrl = TextEditingController(
      text: e?.costPrice.toStringAsFixed(2) ?? '',
    );
    _sellCtrl = TextEditingController(
      text: e?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    _stockCtrl = TextEditingController(text: e?.stockQty.toString() ?? '');
    _unit = e?.unit ?? 'units';
    _recalculate();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final sell = double.tryParse(_sellCtrl.text) ?? 0;
    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    setState(() {
      _margin = cost > 0 ? ((sell - cost) / cost) * 100 : 0;
      _expectedRevenue = sell * stock;
      _expectedProfit = (sell - cost) * stock;
    });
  }

  // ── AI SCAN ──────────────────────────────────────────────────────────────

  Future<void> _scanWithAI() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (photo == null) return;

      setState(() {
        _isAnalysing = true;
        _aiDescription = null;
        _aiConfidence = null;
        _aiImage = File(photo.path);
      });

      EventLoggerService.log(
        'AI',
        'Gemini product analysis started for captured image',
      );

      final result = await GeminiService.analyseProduct(File(photo.path));

      // Auto-fill form fields with AI results
      setState(() {
        _nameCtrl.text = result.name;
        _categoryCtrl.text = result.category;
        _costCtrl.text = result.suggestedCostPrice.toStringAsFixed(0);
        _sellCtrl.text = result.suggestedSellingPrice.toStringAsFixed(0);
        _aiDescription = result.description;
        _aiConfidence = result.confidence;
        _isAnalysing = false;
      });

      _recalculate();

      EventLoggerService.log(
        'AI',
        'Gemini identified: ${result.name} (${(result.confidence * 100).toStringAsFixed(0)}% confidence)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI identified: ${result.name} — review and adjust if needed',
            ),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAnalysing = false);
      EventLoggerService.log('AI', 'Gemini analysis failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI analysis failed. Fill in the details manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final currency = globalSettings.currency;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── AI SCAN BUTTON ──
              if (!isEdit) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withAlpha(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF22C55E),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI Product Recognition',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Point your camera at a product — AI will identify it and auto-fill the form.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 10),

                      // Show captured image preview if available
                      if (_aiImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _aiImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // AI result description
                      if (_aiDescription != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _aiDescription!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI Confidence: ${((_aiConfidence ?? 0) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (_aiConfidence ?? 0) > 0.7
                                      ? const Color(0xFF22C55E)
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      ElevatedButton.icon(
                        onPressed: _isAnalysing ? null : _scanWithAI,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                        ),
                        icon: _isAnalysing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          _isAnalysing
                              ? 'AI Analysing...'
                              : _aiDescription != null
                              ? 'Scan Again'
                              : 'Scan Product with AI',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or fill in manually',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // ── FORM FIELDS ──
              _field(
                _nameCtrl,
                'Item Name',
                Icons.label_outline,
                hint: 'e.g. Samsung TV, Sugar 2kg, Ladies Dress',
              ),
              const SizedBox(height: 14),
              _field(
                _categoryCtrl,
                'Category',
                Icons.category_outlined,
                hint: 'e.g. Electronics, Food, Clothing, Hardware',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      _costCtrl,
                      'Cost Price ($currency)',
                      Icons.shopping_cart_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numField(
                      _sellCtrl,
                      'Selling Price ($currency)',
                      Icons.sell_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      _stockCtrl,
                      'Stock Quantity',
                      Icons.inventory_outlined,
                      isInt: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Live calculation preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withAlpha(80),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Calculation Preview',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _calcRow(
                      'Profit Margin',
                      '${_margin.toStringAsFixed(1)}%',
                      _margin >= 15 ? const Color(0xFF22C55E) : Colors.orange,
                    ),
                    _calcRow(
                      'Expected Revenue',
                      '$currency ${NumberFormat('#,##0.00').format(_expectedRevenue)}',
                      Colors.white,
                    ),
                    _calcRow(
                      'Expected Profit',
                      '$currency ${NumberFormat('#,##0.00').format(_expectedProfit)}',
                      _expectedProfit >= 0
                          ? const Color(0xFF22C55E)
                          : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(
                  isEdit ? 'UPDATE PRODUCT' : 'ADD TO INVENTORY',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
      onChanged: (_) => _recalculate(),
      validator: (v) => ValidatorService.validateProductName(v ?? ''),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isInt = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      onChanged: (_) => _recalculate(),
      validator: (v) => isInt
          ? ValidatorService.validateStockQuantity(v ?? '')
          : ValidatorService.validatePrice(v ?? ''),
    );
  }

  Widget _calcRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    InputHandlerService.handleStockEntrySubmit(
      name: _nameCtrl.text.trim(),
      price: _sellCtrl.text.trim(),
      stock: _stockCtrl.text.trim(),
      onValid: _persistProduct,
      onInvalid: (errors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.values.first),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _persistProduct() async {
    final item = InventoryItem(
      id: widget.existing?.id ?? generateId(),
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      costPrice: double.parse(_costCtrl.text),
      sellingPrice: double.parse(_sellCtrl.text),
      stockQty: int.parse(_stockCtrl.text),
      unitsSold: widget.existing?.unitsSold ?? 0,
      unit: _unit,
      dateAdded: widget.existing?.dateAdded ?? DateTime.now(),
      lastSaleDate: widget.existing?.lastSaleDate,
    );

    if (widget.existing != null) {
      await DatabaseHelper.instance.updateProduct(item);
      final idx = globalInventory.indexWhere((i) => i.id == item.id);
      if (idx != -1) globalInventory[idx] = item;
    } else {
      await DatabaseHelper.instance.insertProduct(item);
      globalInventory.insert(0, item);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing != null
                ? '${item.name} updated and saved'
                : '${item.name} added and saved to database',
          ),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    }
  }
}
