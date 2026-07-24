class AiMessage {
  AiMessage({required this.role, required this.content});

  final String role; // 'user' | 'assistant'
  final String content;

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        role: json['role'] as String,
        content: json['content'] as String,
      );
}
