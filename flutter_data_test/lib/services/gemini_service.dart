// Google Generative AI service for search query optimization
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../config/api_keys.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel model;

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: geminiApiKey,
    );
  }

  Future<String> optimizeSearchQuery(String keyword, String avoidWords, String advancedDescription) async {
    debugPrint("Gemini used");

    if (avoidWords.isNotEmpty) {
      avoidWords = 'Words to avoid: $avoidWords';
    } else {
      avoidWords = 'Words to avoid: none';
    }
    if (advancedDescription.isNotEmpty) {
      advancedDescription = 'Extra context: $advancedDescription';
    } else {
      advancedDescription = 'Extra context: none';
    }

    try {
      final response = await model.generateContent([
        Content.text(
          'Turn this into an optimized YouTube search query. Keep it short, natural, and focused on the main topic. Return only the search query, with no explanation or quotation marks:\n\n$keyword\n$avoidWords\n$advancedDescription',
        ),
      ]);

      final shaped = (response.text ?? '').trim();
      debugPrint(shaped);
      if (shaped.isEmpty) return keyword;
      return shaped;
    } catch (e) {
      debugPrint('Gemini error: $e');
      return keyword;
    }
  }
}
