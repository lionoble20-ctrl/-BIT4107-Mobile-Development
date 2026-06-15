import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../services/world_bank_service.dart'; // LINE 4 — NEW

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'Monthly';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  WorldBankData? _worldBankData; // NEW
  bool _loadingWB = true; // NEW

  @override
  void initState() {
    // NEW
    super.initState();
    _loadWorldBankData();
  }

  Future<void> _loadWorldBankData() async {
    // NEW
    try {
      final data = await WorldBankService.getKenyaData();
      if (mounted)
        setState(() {
          _worldBankData = data;
          _loadingWB = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingWB = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = globalSettings.currency;
    final periodSales = getSalesByPeriod(_selectedPeriod);
    final pnl = PnLSummary.calculate(periodSales, globalInventory);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time P&L Dashboard')),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _periods.map((p) {
                final selected = _selectedPeriod == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.grey,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Hero net profit card
                _heroCard(
                  title: 'Net Profit — $_selectedPeriod',
                  value: '$currency ${fmt.format(pnl.netProfit)}',
                  subtitle: '${pnl.transactionCount} transactions recorded',
                  color: pnl.netProfit >= 0
                      ? const Color(0xFF22C55E)
                      : Colors.red,
                  icon: pnl.netProfit >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                ),
                const SizedBox(height: 12),
                _worldBankCard(pnl), // NEW — World Bank card here
                const SizedBox(height: 12), // NEW
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Total Revenue',
                        '$currency ${fmt.format(pnl.totalRevenue)}',
                        const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'Total Cost',
                        '$currency ${fmt.format(pnl.totalCost)}',
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Realized Margin',
                        '${pnl.realizedMargin.toStringAsFixed(1)}%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'Stagnant Risk',
                        '$currency ${fmt.format(pnl.stagnantRisk)}',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Best Product',
                        pnl.bestProduct,
                        const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'Needs Attention',
                        pnl.worstProduct,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (pnl.lossRiskItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Loss Risk Items',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...pnl.lossRiskItems.map(
                          (n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• $n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Asset Ledger Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (globalInventory.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Add products to see breakdown',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...globalInventory.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.pie_chart,
                          color: Colors.blue,
                          size: 20,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${item.category} • Sold: ${item.unitsSold} | Stock: ${item.stockQty} ${item.unit}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.totalProfitGenerated >= 0 ? "+" : ""}$currency ${NumberFormat('#,##0').format(item.totalProfitGenerated)}',
                              style: TextStyle(
                                color: item.totalProfitGenerated >= 0
                                    ? const Color(0xFF22C55E)
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item.profitMarginPercent.toStringAsFixed(0)}% margin',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW — World Bank card widget
  Widget _worldBankCard(PnLSummary pnl) {
    if (_loadingWB) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_worldBankData == null) return const SizedBox();

    final inflation = _worldBankData!.inflationRate;
    final gdp = _worldBankData!.gdpGrowth;
    final margin = pnl.realizedMargin;
    final beatsInflation = margin > inflation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text(
                '🌍 Kenya Economic Context',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kenya Inflation Rate',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '${inflation.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Profit Margin',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '${margin.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white12),
          Row(
            children: [
              Icon(
                beatsInflation ? Icons.check_circle : Icons.warning_amber,
                color: beatsInflation ? const Color(0xFF22C55E) : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  beatsInflation
                      ? 'Your margin beats inflation by ${(margin - inflation).toStringAsFixed(1)}% — business growing in real value ✅'
                      : 'Your margin is below inflation by ${(inflation - margin).toStringAsFixed(1)}% — consider raising prices ⚠️',
                  style: TextStyle(
                    color: beatsInflation
                        ? const Color(0xFF22C55E)
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                gdp > 0 ? Icons.trending_up : Icons.trending_down,
                color: gdp > 0 ? const Color(0xFF22C55E) : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kenya GDP Growth: ${gdp.toStringAsFixed(1)}% — ${gdp > 4 ? "Strong economy, good time to expand 📈" : "Slow growth, focus on efficiency 📉"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(80), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
