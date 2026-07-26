class SupportTicketSummary {
  SupportTicketSummary({
    required this.id,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String subject;
  final String status;
  final DateTime createdAt;

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) => SupportTicketSummary(
        id: json['id'] as String,
        category: json['category'] as String,
        subject: json['subject'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SupportTicketMessageItem {
  SupportTicketMessageItem({required this.authorRole, required this.content, required this.createdAt});

  final String authorRole; // 'user' | 'admin'
  final String content;
  final DateTime createdAt;

  factory SupportTicketMessageItem.fromJson(Map<String, dynamic> json) => SupportTicketMessageItem(
        authorRole: json['authorRole'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SupportTicketDetail extends SupportTicketSummary {
  SupportTicketDetail({
    required super.id,
    required super.category,
    required super.subject,
    required super.status,
    required super.createdAt,
    required this.messages,
  });

  final List<SupportTicketMessageItem> messages;

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) => SupportTicketDetail(
        id: json['id'] as String,
        category: json['category'] as String,
        subject: json['subject'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        messages: (json['messages'] as List)
            .map((e) => SupportTicketMessageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
