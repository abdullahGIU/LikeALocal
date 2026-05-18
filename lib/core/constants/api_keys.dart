/// Mapbox access token — https://account.mapbox.com/access-tokens/
/// Override: `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token`
class ApiKeys {
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue:
        'pk.eyJ1IjoibWFzb3VkNjkiLCJhIjoiY21wOXN1enpzMDk1ZjJxcGM1MHYybDUyZyJ9.s8qqx5ID7KL8swPjp-Jl-Q',
  );

  static bool get hasMapboxToken => mapboxAccessToken.isNotEmpty;

  /// Gemini API key — https://aistudio.google.com/apikey
  /// Override: `flutter run --dart-define=GEMINI_API_KEY=your_key`
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
