class VehicleDocument {
  VehicleDocument({
    required this.id,
    required this.type,
    required this.viewUrl,
    this.expiryDate,
    required this.verified,
  });

  final String id;
  final String type;

  /// Short-lived signed link minted by the API on each read — documents are
  /// private, so this is not a permanent address and shouldn't be cached.
  final String viewUrl;
  final DateTime? expiryDate;
  final bool verified;

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] as String,
      type: json['type'] as String,
      viewUrl: json['viewUrl'] as String? ?? '',
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
