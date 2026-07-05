/// gemini_service.dart
/// AI-powered product recognition service using Google Gemini Vision.
/// Analyses a product image and returns name, category, and suggested prices.
library;

import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:retailapp/api_config.dart';

class ProductAnalysisResult {
  final String name;
  final String category;
  final double suggestedCostPrice;
  final double suggestedSellingPrice;
  final String description;
  final double confidence;

  ProductAnalysisResult({
    required this.name,
    required this.category,
    required this.suggestedCostPrice,
    required this.suggestedSellingPrice,
    required this.description,
    required this.confidence,
  });
}

class GeminiService {
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: geminiApiKey,
  );

  /// Analyses a product image and returns structured product information.
  static Future<ProductAnalysisResult> analyseProduct(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    const prompt = '''
You are a retail product analyst for a Kenyan retail shop.
Analyse this product image and respond ONLY with a valid JSON object
in exactly this format, nothing else:

{
  "name": "product name here",
  "category": "product category here",
  "suggested_cost_price_kes": 0,
  "suggested_selling_price_kes": 0,
  "description": "one sentence description",
  "confidence": 0.0
}

Rules:
- name: specific product name (e.g. "Samsung Galaxy A15", "Coca Cola 500ml")
- category: one of these only: Electronics, Food, Clothing, Hardware, Furniture, Stationery, Beauty, Other
- suggested_cost_price_kes: realistic wholesale price in Kenyan Shillings (integer)
- suggested_selling_price_kes: realistic retail price in Kenyan Shillings (integer, higher than cost)
- description: one short sentence about the product
- confidence: your confidence score between 0.0 and 1.0
- If you cannot identify the product clearly, still return the JSON with your best guess and a low confidence score
''';

    final response = await _model.generateContent([
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ]);

    final text = response.text ?? '';

    // Extract JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}', multiLine: true).firstMatch(text);

    if (jsonMatch == null) {
      throw Exception('AI response was not in expected format');
    }

    final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

    return ProductAnalysisResult(
      name: json['name'] as String? ?? 'Unknown Product',
      category: json['category'] as String? ?? 'Other',
      suggestedCostPrice:
          (json['suggested_cost_price_kes'] as num?)?.toDouble() ?? 0,
      suggestedSellingPrice:
          (json['suggested_selling_price_kes'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}
