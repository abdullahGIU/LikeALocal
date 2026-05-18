import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';
import '../models/ai_message.dart';
import '../models/place.dart';

class AiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Chat-style reply using conversation history + optional nearby places context.
  Future<String> chat({
    required String userMessage,
    List<AiMessage> history = const [],
    List<Place> nearbyPlaces = const [],
    String? budget,
    String? atmosphere,
    String? cityHint,
  }) async {
    final systemContext = _buildContext(
      nearbyPlaces: nearbyPlaces,
      budget: budget,
      atmosphere: atmosphere,
      cityHint: cityHint,
    );

    final prompt = StringBuffer()
      ..writeln(systemContext)
      ..writeln()
      ..writeln('Conversation:');

    for (final msg in history.take(8)) {
      final role = msg.isUser ? 'User' : 'Assistant';
      prompt.writeln('$role: ${msg.text}');
    }
    prompt.writeln('User: $userMessage');
    prompt.writeln('Assistant:');

    if (!ApiKeys.hasGeminiKey) {
      return _mockResponse(
        userMessage: userMessage,
        nearbyPlaces: nearbyPlaces,
        budget: budget,
        atmosphere: atmosphere,
      );
    }

    try {
      return await _callGemini(prompt.toString());
    } catch (_) {
      return _mockResponse(
        userMessage: userMessage,
        nearbyPlaces: nearbyPlaces,
        budget: budget,
        atmosphere: atmosphere,
      );
    }
  }

  /// Structured recommendations for home/search cards.
  Future<String> getRecommendations({
    required List<Place> nearbyPlaces,
    String budget = 'medium',
    String atmosphere = 'lively',
    String? locationLabel,
  }) async {
    final prompt = '''
Recommend exactly 3 local places from this list for a traveler.
Budget preference: $budget
Atmosphere preference: $atmosphere
${locationLabel != null ? 'Area: $locationLabel' : ''}

Places:
${_formatPlaces(nearbyPlaces.take(12))}

Reply with a short intro then 3 bullet points: **Place Name** — one sentence why.
Keep it friendly and specific.''';

    if (!ApiKeys.hasGeminiKey) {
      return _mockRecommendations(nearbyPlaces, budget, atmosphere);
    }

    try {
      return await _callGemini(prompt);
    } catch (_) {
      return _mockRecommendations(nearbyPlaces, budget, atmosphere);
    }
  }

  Future<String> _callGemini(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 512,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) throw Exception('Empty AI response');

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) throw Exception('No text in response');

    final text = parts.first['text'] as String? ?? '';
    if (text.trim().isEmpty) throw Exception('Empty text');
    return text.trim();
  }

  String _buildContext({
    required List<Place> nearbyPlaces,
    String? budget,
    String? atmosphere,
    String? cityHint,
  }) {
    final buffer = StringBuffer(
      'You are LikeALocal, a friendly local travel assistant. '
      'Suggest real places from the list when possible. Be concise.',
    );
    if (budget != null) buffer.writeln('User budget: $budget');
    if (atmosphere != null) buffer.writeln('User atmosphere: $atmosphere');
    if (cityHint != null) buffer.writeln('User area: $cityHint');
    if (nearbyPlaces.isNotEmpty) {
      buffer.writeln('\nNearby places:\n${_formatPlaces(nearbyPlaces.take(15))}');
    }
    return buffer.toString();
  }

  String _formatPlaces(Iterable<Place> places) {
    if (places.isEmpty) return '(no places loaded)';
    return places
        .map((p) {
          final dist = p.distanceKm != null
              ? ' — ${p.distanceKm!.toStringAsFixed(1)} km'
              : '';
          return '- ${p.name} (${p.category}, ${p.budget}, ${p.atmosphere})$dist';
        })
        .join('\n');
  }

  String _mockResponse({
    required String userMessage,
    required List<Place> nearbyPlaces,
    String? budget,
    String? atmosphere,
  }) {
    final query = userMessage.toLowerCase();
    var matches = nearbyPlaces.where((p) {
      return query.split(' ').any(
            (word) =>
                word.length > 3 &&
                (p.name.toLowerCase().contains(word) ||
                    p.category.toLowerCase().contains(word)),
          );
    }).take(3).toList();

    if (matches.isEmpty && nearbyPlaces.isNotEmpty) {
      matches = nearbyPlaces.take(3).toList();
    }

    final budgetLine = budget != null ? ' ($budget budget)' : '';
    final vibe = atmosphere ?? 'local';

    if (matches.isEmpty) {
      return 'I can help you discover cafés, restaurants, parks, and museums near you. '
          'Try enabling location or searching first, then ask again!\n\n'
          'Tip: Add a Gemini API key with --dart-define=GEMINI_API_KEY=... for smarter answers.';
    }

    final bullets = matches
        .map((p) => '• **${p.name}** — ${p.category}, ${p.atmosphere} vibe$budgetLine')
        .join('\n');

    return 'Here are some $vibe spots based on your request:\n\n$bullets\n\n'
        '(Demo mode — add GEMINI_API_KEY for full AI responses.)';
  }

  String _mockRecommendations(
    List<Place> places,
    String budget,
    String atmosphere,
  ) {
    final picks = places.take(3).toList();
    if (picks.isEmpty) {
      return 'Enable location and refresh to get AI picks near you.';
    }
    final lines = picks
        .map(
          (p) =>
              '• **${p.name}** — Great ${p.category.toLowerCase()} for $atmosphere vibes on a $budget budget.',
        )
        .join('\n');
    return 'AI Suggested Places ($atmosphere, $budget):\n\n$lines';
  }
}
