import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';
import '../models/ai_message.dart';
import '../models/place.dart';

class AiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const _systemPersona = '''
You are **LikeALocal**, a warm, knowledgeable local friend helping travelers discover real places.

Your style:
- Sound natural and enthusiastic — like a local texting a friend, not a robot.
- Use short paragraphs and bullet points when listing places.
- Mention **place names in bold** when recommending from the list.
- Add a quick insider tip when helpful (best time to go, what to order, vibe).
- If the user asks something vague, ask one friendly follow-up question OR offer 2–3 tailored options.
- Only recommend places from the provided nearby list — never invent venues.
- Include distance when available (e.g. "about 1.2 km away").
- Keep answers focused (roughly 80–180 words unless they ask for more).
''';

  /// Chat-style reply using conversation history + optional nearby places context.
  Future<String> chat({
    required String userMessage,
    List<AiMessage> history = const [],
    List<Place> nearbyPlaces = const [],
    String? budget,
    String? atmosphere,
    String? cityHint,
  }) async {
    final placesBlock = nearbyPlaces.isEmpty
        ? 'No nearby places loaded yet — encourage enabling location and refreshing the app.'
        : 'Nearby places (use only these):\n${_formatPlaces(nearbyPlaces.take(18))}';

    final prefs = StringBuffer();
    if (budget != null) prefs.writeln('User budget preference: $budget');
    if (atmosphere != null) prefs.writeln('User vibe preference: $atmosphere');
    if (cityHint != null) prefs.writeln('Area context: $cityHint');

    final historyBlock = _formatHistory(history);

    final userTurn = '''
$placesBlock

${prefs.isNotEmpty ? '$prefs\n' : ''}$historyBlock
User: $userMessage

Reply as LikeALocal:''';

    if (!ApiKeys.hasGeminiKey) {
      return _mockResponse(
        userMessage: userMessage,
        nearbyPlaces: nearbyPlaces,
        budget: budget,
        atmosphere: atmosphere,
      );
    }

    try {
      return await _callGemini(
        userMessage: userTurn,
        systemInstruction: _systemPersona,
      );
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
    final shuffledPlaces = List<Place>.from(nearbyPlaces)..shuffle();

    final placesBlock = shuffledPlaces.isEmpty
        ? '(no places loaded)'
        : _formatPlaces(shuffledPlaces.take(12));

    final fullPrompt = '''
$placesBlock

Recommend exactly 3 places from the list above for a traveler.
Budget: $budget | Atmosphere: $atmosphere
${locationLabel != null ? 'Area: $locationLabel' : ''}

Write a warm 1-sentence intro, then 3 bullets: **Place Name** — why it fits (distance if known).
Sound like a local friend, not a search engine.''';

    if (!ApiKeys.hasGeminiKey) {
      return _mockRecommendations(shuffledPlaces, budget, atmosphere);
    }

    try {
      return await _callGemini(
        userMessage: fullPrompt,
        systemInstruction: _systemPersona,
      );
    } catch (_) {
      return _mockRecommendations(shuffledPlaces, budget, atmosphere);
    }
  }

  Future<String> _callGemini({
    required String userMessage,
    required String systemInstruction,
  }) async {
    final uri = Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.88,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
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

  String _formatHistory(List<AiMessage> history) {
    if (history.isEmpty) return '';
    final buffer = StringBuffer('Recent conversation:\n');
    for (final msg in history.take(10)) {
      final role = msg.isUser ? 'User' : 'LikeALocal';
      buffer.writeln('$role: ${msg.text}');
    }
    return '${buffer.toString()}\n';
  }

  String _formatPlaces(Iterable<Place> places) {
    if (places.isEmpty) return '(no places loaded)';
    return places
        .map((p) {
          final dist = p.distanceKm != null
              ? ', ${p.distanceKm!.toStringAsFixed(1)} km away'
              : '';
          final open = p.isOpen ? 'open' : 'closed';
          return '• ${p.name} — ${p.category}, ${p.budget} budget, ${p.atmosphere} vibe, $open$dist';
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
      return query.split(RegExp(r'\s+')).any(
            (word) =>
                word.length > 3 &&
                (p.name.toLowerCase().contains(word) ||
                    p.category.toLowerCase().contains(word) ||
                    p.atmosphere.toLowerCase().contains(word)),
          );
    }).take(3).toList();

    if (matches.isEmpty && nearbyPlaces.isNotEmpty) {
      matches = nearbyPlaces.take(3).toList();
    }

    final vibe = atmosphere ?? 'local';
    final budgetLabel = budget ?? 'flexible';

    if (matches.isEmpty) {
      return 'Hey! 👋 I’d love to help, but I don’t have places loaded near you yet.\n\n'
          'Try turning on location and pulling to refresh on Home — then ask me again. '
          'I can suggest cafés, restaurants, parks, and hidden gems based on what’s actually around you.\n\n'
          '_Tip: run with `--dart-define=GEMINI_API_KEY=...` for full AI answers._';
    }

    final intro = _pickIntro(userMessage);
    final bullets = matches.map((p) {
      final dist = p.distanceKm != null
          ? ' (${p.distanceKm!.toStringAsFixed(1)} km)'
          : '';
      final tip = _quickTip(p);
      return '• **${p.name}**$dist — ${p.category}, ${p.atmosphere} vibe. $tip';
    }).join('\n');

    return '$intro\n\n$bullets\n\n'
        'Want something more $vibe or closer to a **$budgetLabel** budget? Just say the word!';
  }

  String _pickIntro(String message) {
    final m = message.toLowerCase();
    if (m.contains('cheap') || m.contains('budget')) {
      return 'Great question — here are some solid picks that won’t break the bank:';
    }
    if (m.contains('romantic') || m.contains('date')) {
      return 'Ooh, nice — for a date-night feel, I’d start with these:';
    }
    if (m.contains('coffee') || m.contains('café') || m.contains('cafe')) {
      return 'If you’re chasing a good cup and a good vibe, locals often go here:';
    }
    if (m.contains('quiet') || m.contains('work')) {
      return 'For a calmer spot to settle in, I’d recommend:';
    }
    return 'Based on what’s around you right now, I’d check out:';
  }

  String _quickTip(Place p) {
    switch (p.category) {
      case 'Cafés':
        return 'Good for a slow morning or laptop session.';
      case 'Restaurants':
        return 'Ask what’s popular today — portions are usually generous.';
      case 'Parks':
        return 'Best around golden hour if you want photos.';
      case 'Museums':
        return 'Worth checking hours before you go.';
      default:
        return 'Worth a quick look on the map.';
    }
  }

  String _mockRecommendations(
    List<Place> places,
    String budget,
    String atmosphere,
  ) {
    final picks = places.take(3).toList();
    if (picks.isEmpty) {
      return 'Turn on location and refresh Home — I’ll have personalized picks for you in a second!';
    }
    final lines = picks
        .map((p) {
          final dist = p.distanceKm != null
              ? ' · ${p.distanceKm!.toStringAsFixed(1)} km'
              : '';
          return '• **${p.name}**$dist — perfect for a **$atmosphere** mood on a **$budget** budget.';
        })
        .join('\n');
    return 'Here’s what I’d suggest for you today:\n\n$lines';
  }
}
