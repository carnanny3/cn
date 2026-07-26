class ChecklistItem {
  ChecklistItem({required this.label, required this.done});

  final String label;
  final bool done;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      ChecklistItem(label: json['label'] as String, done: json['done'] as bool? ?? false);
}

class ConciergeOrderItem {
  ConciergeOrderItem({
    required this.id,
    required this.orderType,
    required this.status,
    this.vehicleLabel,
    required this.checklist,
    required this.createdAt,
  });

  final String id;
  final String orderType;
  final String status;
  final String? vehicleLabel;
  final List<ChecklistItem> checklist;
  final DateTime createdAt;

  factory ConciergeOrderItem.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final checklistJson = json['documentChecklist'] as Map<String, dynamic>?;
    final items = (checklistJson?['items'] as List? ?? [])
        .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ConciergeOrderItem(
      id: json['id'] as String,
      orderType: json['orderType'] as String,
      status: json['status'] as String,
      vehicleLabel: vehicle != null ? '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}' : null,
      checklist: items,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
