import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/world_bank_service.dart'; // NEW
import 'ai_assistant_screen.dart'; // NEW

class PredictiveAdvisoryScreen extends StatefulWidget {
  const PredictiveAdvisoryScreen({super.key});

  @override
  State<PredictiveAdvisoryScreen> createState() =>
      _PredictiveAdvisoryScreenState();
}

class _PredictiveAdvisoryScreenState extends State<PredictiveAdvisoryScreen> {
  final _questionCtrl = TextEditingController();
  String _answer = '';
  bool _showAnswer = false;
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
      if (mounted) {
        setState(() {
          _worldBankData = data;
          _loadingWB = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingWB = false);
    }
  }

  double get _confidenceLevel {
    if (globalInventory.isEmpty) return 0;
    final withSales = globalInventory.where((i) => i.unitsSold > 0).length;
    return (withSales / globalInventory.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = generateAdvisory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligent Advisory Engine'),
        actions: [
          // NEW - Business Assistant entry point
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Business Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiAssistantScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Confidence card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22C55E).withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF22C55E), size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATISTICAL ENGINE CONFIDENCE',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data Accuracy: ${_confidenceLevel.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        globalInventory.isEmpty
                            ? 'Add products to start generating insights'
                            : 'Based on ${globalInventory.length} products and ${globalSales.length} sales records',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NEW — World Bank Advisory Card
          _worldBankAdvisoryCard(),
          const SizedBox(height: 16),

          // Q&A section
          const Text(
            'Ask Your Business a Question',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Am I making a profit this week?',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF22C55E)),
                onPressed: _askQuestion,
              ),
            ),
            onSubmitted: (_) => _askQuestion(),
          ),
          if (_showAnswer && _answer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF22C55E).withAlpha(60),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Color(0xFF22C55E),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _answer,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Quick question chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Am I making a profit?',
                      'What should I restock?',
                      'What is my best product?',
                      'What are my stagnant items?',
                      'What are my loss risks?',
                      'Show me my breakeven',
                      'What is my revenue this month?',
                    ]
                    .map(
                      (q) => GestureDetector(
                        onTap: () {
                          _questionCtrl.text = q;
                          _askQuestion();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF22C55E).withAlpha(60),
                            ),
                          ),
                          child: Text(
                            q,
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),

          // Recommendations
          const Text(
            'Strategic Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...suggestions.map((s) => _SuggestionCard(data: s)),
        ],
      ),
    );
  }

  // NEW — World Bank Advisory Widget
  Widget _worldBankAdvisoryCard() {
    if (_loadingWB) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueAccent.withAlpha(80)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading Kenya economic data...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_worldBankData == null) return const SizedBox();

    final inflation = _worldBankData!.inflationRate;
    final gdp = _worldBankData!.gdpGrowth;

    // Generate advice based on economic data
    final List<Map<String, dynamic>> economicAdvice = [];

    if (inflation > 7) {
      economicAdvice.add({
        'icon': Icons.warning_amber,
        'color': Colors.red,
        'advice':
            'High inflation at ${inflation.toStringAsFixed(1)}% — raise your prices immediately to protect margins.',
      });
    } else if (inflation > 4) {
      economicAdvice.add({
        'icon': Icons.info_outline,
        'color': Colors.orange,
        'advice':
            'Moderate inflation at ${inflation.toStringAsFixed(1)}% — review prices every 3 months to stay ahead.',
      });
    } else {
      economicAdvice.add({
        'icon': Icons.check_circle,
        'color': const Color(0xFF22C55E),
        'advice':
            'Low inflation at ${inflation.toStringAsFixed(1)}% — stable pricing environment, good time to grow.',
      });
    }

    if (gdp > 5) {
      economicAdvice.add({
        'icon': Icons.trending_up,
        'color': const Color(0xFF22C55E),
        'advice':
            'Strong GDP growth at ${gdp.toStringAsFixed(1)}% — consumer spending is rising, expand your stock now.',
      });
    } else if (gdp > 3) {
      economicAdvice.add({
        'icon': Icons.trending_flat,
        'color': Colors.orange,
        'advice':
            'Moderate GDP growth at ${gdp.toStringAsFixed(1)}% — economy is stable, focus on high-margin products.',
      });
    } else {
      economicAdvice.add({
        'icon': Icons.trending_down,
        'color': Colors.red,
        'advice':
            'Slow GDP growth at ${gdp.toStringAsFixed(1)}% — consumers spending less, cut slow-moving stock.',
      });
    }

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
                '🌍 Kenya Market Intelligence',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Live advice based on World Bank economic data',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const Divider(height: 16, color: Colors.white12),
          ...economicAdvice.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['advice'] as String,
                      style: TextStyle(
                        color: item['color'] as Color,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 8, color: Colors.white12),
          Text(
            'Source: World Bank Open Data — Kenya 2024',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _askQuestion() {
    setState(() {
      _answer = answerQuestion(_questionCtrl.text);
      _showAnswer = true;
    });
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SuggestionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      'green': const Color(0xFF22C55E),
      'orange': Colors.orange,
      'red': Colors.red,
      'blue': Colors.blue,
    };
    final color = colorMap[data['color']] ?? const Color(0xFF22C55E);
    final confidence = data['confidence'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['title'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  confidence,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['message'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (data['extra'] != null) ...[
            const SizedBox(height: 6),
            Text(
              '→ ${data['extra']}',
              style: TextStyle(color: color, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
