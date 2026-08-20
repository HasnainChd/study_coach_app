import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get geminiApiKey =>
      (dotenv.env['API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '').trim();

  static String get cerebrasApiKey => (dotenv.env['GROQ_API_KEY'] ?? '').trim();

  static const String cerebrasModel = 'openai/gpt-oss-120b';
  static const String cerebrasBaseUrl = 'https://api.groq.com/openai/v1';
}
