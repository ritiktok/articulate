import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get openaiApiUrl =>
      dotenv.env['OPENAI_API_URL'] ??
      'https://api.openai.com/v1/chat/completions';
  static String get openaiModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  static const int maxSuggestions = 5;
  static const double defaultConfidence = 0.8;
  static const int maxTokens = 300;
  static const double temperature = 0.7;

  static const int snapshotSize = 256;
  static const int maxRecentStrokes = 5;

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static const String appName = 'Articulate';

  static const String voiceResponseAnimation =
      'assets/animations/voice_response.json';
  static const String canvasRippleAnimation =
      'assets/animations/canvas_ripple.json';

  static bool get isOpenAIConfigured =>
      openaiApiKey.isNotEmpty && openaiApiKey != 'YOUR_OPENAI_API_KEY';
}
