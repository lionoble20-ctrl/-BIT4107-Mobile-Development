import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

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

  double get _confidenceLevel {
    if (globalInventory.isEmpty) return 0;
    final withSales = globalInventory.where((i) => i.unitsSold > 0).length;
    return (withSales / globalInventory.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = generateAdvisory();

    return Scaffold(
      appBar: AppBar(title: const Text('Intelligent Advisory Engine')),
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
          const SizedBox(height: 20),

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
          ...suggestions.map((s) => _SuggestionCard(data: s)).toList(),
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
