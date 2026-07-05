import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String geminiApiKey = dotenv.env['API_KEY'] ?? '';
}
