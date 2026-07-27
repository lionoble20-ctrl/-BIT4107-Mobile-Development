import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  /// Sends a merchant's question to Groq along with optional app context
  /// (e.g. stock summary, recent sales) and returns the assistant's reply.
  static Future<String> askAssistant({
    required String userMessage,
    String? appContext,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Error: Groq API key not configured. Check key.properties.';
    }

    final systemPrompt = appContext != null && appContext.isNotEmpty
        ? 'You are a helpful assistant for a retail shop merchant using the '
              'Retail Analytics Engine app. Use the following current app data '
              'to answer questions accurately when relevant:\n$appContext\n\n'
              'Keep answers concise and practical.'
        : 'You are a helpful assistant for a retail shop merchant using the '
              'Retail Analytics Engine app. Keep answers concise and practical.';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content == null) {
          return 'Error: Unexpected response format from Groq.';
        }
        return content.toString().trim();
      } else {
        return 'Error: Groq API returned status ${response.statusCode}. '
            '${response.body}';
      }
    } catch (e) {
      return 'Error: Failed to reach Groq API. $e';
    }
  }
}
