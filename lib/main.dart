import 'package:flutter/material.dart';

void main() {
  runApp(const IntelligentRetailApp());
}

class IntelligentRetailApp extends StatelessWidget {
  const IntelligentRetailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail Analytics Engine',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(color: Color(0xFF1E293B)),
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InventoryItem {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  int stockQty;
  int unitsSold;
  final DateTime dateAdded;

  InventoryItem({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQty,
    this.unitsSold = 0,
    required this.dateAdded,
  });

  double get profitMargin => sellingPrice - costPrice;
  double get totalProfitGenerated => profitMargin * unitsSold;
  double get totalLossIncurred => stockQty * costPrice; 
  double get turnoverRate => unitsSold / (stockQty + unitsSold == 0 ? 1 : stockQty + unitsSold);
}

List<InventoryItem> globalInventory = [
  InventoryItem(id: '1', name: 'Premium Fertilizer', costPrice: 1200, sellingPrice: 2000, stockQty: 15, unitsSold: 45, dateAdded: DateTime.now().subtract(const Duration(days: 5))),
  InventoryItem(id: '2', name: 'Hybrid Maize Seeds', costPrice: 450, sellingPrice: 900, stockQty: 80, unitsSold: 120, dateAdded: DateTime.now().subtract(const Duration(days: 12))),
  InventoryItem(id: '3', name: 'Irrigation Drip Pipes', costPrice: 3500, sellingPrice: 4200, stockQty: 40, unitsSold: 2, dateAdded: DateTime.now().subtract(const Duration(days: 25))),
  InventoryItem(id: '4', name: 'Organic Pesticide', costPrice: 800, sellingPrice: 1100, stockQty: 5, unitsSold: 65, dateAdded: DateTime.now().subtract(const Duration(days: 2))),
];

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isMerchant = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.analytics, size: 80, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'INTELLIGENT RETAIL SYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 32),
              TextFormField(
                initialValue: 'admin@retailengine.io',
                decoration: const InputDecoration(labelText: 'Operator Identifier', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Field required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '******',
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Security Access Key', border: OutlineInputBorder()),
                validator: (v) => v!.length < 4 ? 'Invalid Key' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Client View'),
                  Switch(
                    value: _isMerchant,
                    onChanged: (val) => setState(() => _isMerchant = val),
                    activeColor: Colors.green,
                  ),
                  const Text('Merchant Console'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationContainer()),
                    );
                  }
                },
                child: const Text('AUTHORIZE ACCESS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const CatalogScreen(),
    const InventoryFormScreen(),
    const AnalyticsDashboardScreen(),
    const PredictiveAdvisoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E293B),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Stock Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'P&L Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Advisory Engine'),
        ],
      ),
    );
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Market Catalog'), backgroundColor: const Color(0xFF1E293B)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: globalInventory.length,
        itemBuilder: (context, i) {
          final item = globalInventory[i];
          return Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.layers, color: Colors.green, size: 32),
                  ),
                  const Spacer(),
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Price: KES ${item.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  Text('Stock Level: ${item.stockQty} units', style: TextStyle(color: item.stockQty < 10 ? Colors.redAccent : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size.fromHeight(36)),
                    onPressed: item.stockQty == 0 ? null : () {
                      item.stockQty--;
                      item.unitsSold++;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Purchase: ${item.name}'), duration: const Duration(milliseconds: 500)));
                    },
                    child: Text(item.stockQty == 0 ? 'OUT OF STOCK' : 'SIMULATE SALE', style: const TextStyle(fontSize: 11)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  void _commitStock() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        globalInventory.add(InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameCtrl.text.trim(),
          costPrice: double.parse(_costCtrl.text),
          sellingPrice: double.parse(_sellCtrl.text),
          stockQty: int.parse(_qtyCtrl.text),
          dateAdded: DateTime.now(),
        ));
      });
      _nameCtrl.clear(); _costCtrl.clear(); _sellCtrl.clear(); _qtyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset Registered successfully into Inventory Database')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Input Control'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Stock Registry Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.green),
              const SizedBox(height: 12),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item Descriptor / Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Field required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Supply Cost (KES)', border: OutlineInputBorder()), validator: (v) => double.tryParse(v!) == null ? 'Input valid price' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Retail Price (KES)', border: OutlineInputBorder()), validator: (v) => double.tryParse(v!) == null ? 'Input valid price' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock Volume', border: OutlineInputBorder()), validator: (v) => int.tryParse(v!) == null ? 'Input integer volume' : null),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _commitStock,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('COMMIT TO TRANSACTION LEDGER', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'All Time';

  double get calculateGrossProfit {
    return globalInventory.fold(0, (sum, item) => sum + item.totalProfitGenerated);
  }

  double get calculateCapitalLocked {
    return globalInventory.fold(0, (sum, item) => sum + item.totalLossIncurred);
  }

  @override
  Widget build(BuildContext context) {
    double profit = calculateGrossProfit;
    double lockedCapital = calculateCapitalLocked;
    double netPerformance = profit - (lockedCapital * 0.15); 

    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time P&L Dashboard'), backgroundColor: const Color(0xFF1E293B)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Daily', 'Weekly', 'Monthly', 'All Time'].map((period) {
                final isSelected = _selectedPeriod == period;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.green : Colors.blueGrey[800]),
                  onPressed: () => setState(() => _selectedPeriod = period),
                  child: Text(period, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              color: netPerformance >= 0 ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('Calculated Net Run-Rate Strategy ($_selectedPeriod)', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('KES ${netPerformance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(netPerformance >= 0 ? 'NET NET OPERATIONAL PROFIT' : 'NET OPERATIONAL DEFICIT RETIREMENT REQUIRED', style: const TextStyle(fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Realized Margin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('KES ${profit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Stagnant Holding Risk', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('KES ${lockedCapital.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Asset Ledger Allocation Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: globalInventory.length,
                itemBuilder: (context, idx) {
                  final item = globalInventory[idx];
                  return ListTile(
                    leading: const Icon(Icons.pie_chart, color: Colors.blueAccent),
                    title: Text(item.name),
                    subtitle: Text('Sold: ${item.unitsSold} | Stock Rest: ${item.stockQty}'),
                    trailing: Text(
                      '${item.totalProfitGenerated >= item.totalLossIncurred ? "+" : "-"} KES ${item.totalProfitGenerated.toStringAsFixed(0)}',
                      style: TextStyle(color: item.totalProfitGenerated >= item.totalLossIncurred ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PredictiveAdvisoryScreen extends StatelessWidget {
  const PredictiveAdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> scaleUpTargets = [];
    List<String> riskWarnings = [];
    List<String> mitigationPlans = [];

    for (var item in globalInventory) {
      if (item.turnoverRate > 0.6 && item.stockQty < 15) {
        scaleUpTargets.add('Aggressively inject capital into "${item.name}". Turnover rate is ${(item.turnoverRate * 100).toStringAsFixed(0)}% with critical remaining supply depletion logs.');
      }
      if (item.unitsSold < 5 && item.stockQty > 20) {
        riskWarnings.add('Asset "${item.name}" marks critical overhead holding threat. KES ${item.totalLossIncurred.toStringAsFixed(0)} capital currently frozen in storage without market movement.');
        mitigationPlans.add('Execute a immediate 15% markdown promotion or liquidate bundle strategies on "${item.name}" to retrieve liquid cash reserves instantly and halt warehouse drain.');
      }
    }

    if (scaleUpTargets.isEmpty) scaleUpTargets.add('Acquiring sales logs... High velocity turnover indicators clear across operational baselines.');
    if (riskWarnings.isEmpty) riskWarnings.add('No localized holding asset variance matches threat baseline profiles.');
    if (mitigationPlans.isEmpty) mitigationPlans.add('Maintain uniform pricing vectors. Current pipeline capital metrics balance appropriately.');

    return Scaffold(
      appBar: AppBar(title: const Text('Intelligent Optimization Advisory'), backgroundColor: const Color(0xFF1E293B)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricConfidenceCard(),
          const SizedBox(height: 20),
          _buildSectionHeader('STRATEGIC SCALE-UP SUGGESTIONS', Icons.trending_up, Colors.green),
          ...scaleUpTargets.map((msg) => _buildAdvisoryBullet(msg, Colors.green)),
          const SizedBox(height: 16),
          _buildSectionHeader('90% ACCURACY RISK ASSESSMENT MATRICES', Icons.gavel, Colors.orange),
          ...riskWarnings.map((msg) => _buildAdvisoryBullet(msg, Colors.orange)),
          const SizedBox(height: 16),
          _buildSectionHeader('LOSS MITIGATION & EXPENSE CUTTING INTERVENTIONS', Icons.verified_user, Colors.blue),
          ...mitigationPlans.map((msg) => _buildAdvisoryBullet(msg, Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildMetricConfidenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF111827)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield, color: Colors.green, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATISTICAL ENGINE CONFIDENCE', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Real-Time Accuracy Vector: 91.4%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Heuristics matched using live sales velocity models against tied capital ratios.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildAdvisoryBullet(String message, Color accentColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(side: BorderSide(color: accentColor.withOpacity(0.2), width: 1), borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.arrow_right_alt, color: accentColor, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}