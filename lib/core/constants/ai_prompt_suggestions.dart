import 'dart:math';

/// Large pool of tap-to-send prompts for the AI chat screen.
class AiPromptSuggestions {
  AiPromptSuggestions._();

  static final _random = Random();

  static const List<String> _all = [
    'Best cheap eats near me right now',
    'Where can I get authentic local seafood?',
    'Quiet café with good Wi‑Fi for working',
    'Romantic dinner spot for tonight',
    'Family-friendly restaurants nearby',
    'Best coffee shops within walking distance',
    'Hidden gem restaurants locals love',
    'Late-night food options around here',
    'Healthy lunch places under 15 minutes away',
    'Traditional food with a lively atmosphere',
    'Best brunch spots for the weekend',
    'Vegetarian-friendly restaurants near me',
    'Scenic parks to relax this afternoon',
    'Museums worth visiting today',
    'Kid-friendly parks and playgrounds',
    'Best sunset viewpoint nearby',
    'Cozy place for reading and tea',
    'Street food–style spots on a budget',
    'Fine dining for a special occasion',
    'Places open right now near me',
    'Where do locals actually eat?',
    'Best shawarma or falafel nearby',
    'Dessert and bakery recommendations',
    'Rooftop or outdoor dining options',
    'Quick bite before a meeting',
    'Date-night ideas under medium budget',
    'Solo traveler: safe and welcoming spots',
    'Group dinner for 6 people — suggestions?',
    'Compare two nearby restaurants for me',
    'What should I try if I only have 2 hours?',
    'Rainy day indoor activities nearby',
    'Morning walk + coffee combo nearby',
    'Best rated places within 2 km',
    'Low-key bars or cafés with character',
    'Traditional breakfast like a local',
    'Spicy food lovers — where to go?',
    'Halal options near my location',
    'Places with outdoor seating',
    'Somewhere quiet to take phone calls',
    'Photo-worthy cafés and restaurants',
    'Plan a food crawl with 3 stops nearby',
    'What’s trending in this area?',
    'Surprise me with something unexpected',
    'Best value for money tonight',
    'Near me: museum then lunch nearby',
    'Walking distance from my location',
  ];

  /// Returns a new shuffled list of [count] suggestions.
  static List<String> shuffled({int count = 14}) {
    final copy = List<String>.from(_all)..shuffle(_random);
    return copy.take(count.clamp(1, _all.length)).toList();
  }
}
