class RoadsideRequestItem {
  RoadsideRequestItem({
    required this.id,
    required this.serviceType,
    required this.status,
    this.providerName,
    this.providerPhone,
    this.etaMinutes,
    required this.requestedAt,
  });

  final String id;
  final String serviceType;
  final String status;
  final String? providerName;
  final String? providerPhone;
  final int? etaMinutes;
  final DateTime requestedAt;

  factory RoadsideRequestItem.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as Map<String, dynamic>?;
    return RoadsideRequestItem(
      id: json['id'] as String,
      serviceType: json['serviceType'] as String,
      status: json['status'] as String,
      providerName: provider?['businessName'] as String?,
      providerPhone: provider?['contactPhone'] as String?,
      etaMinutes: json['etaMinutes'] as int?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
    );
  }
}
