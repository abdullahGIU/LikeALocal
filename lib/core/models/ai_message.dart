enum AiMessageRole { user, assistant }

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String text;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  bool get isUser => role == AiMessageRole.user;
}
