class Booking {
  Booking({
    required this.id,
    required this.bookingType,
    required this.status,
    required this.scheduledAt,
    required this.totalAmount,
    this.serviceCategory,
    this.partnerName,
  });

  final String id;
  final String bookingType;
  final String status;
  final DateTime scheduledAt;
  final double totalAmount;
  final String? serviceCategory;
  final String? partnerName;

  String get statusColorKey {
    switch (status) {
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'amber';
    }
  }

  bool get cancellable => status == 'pending' || status == 'confirmed';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        bookingType: json['bookingType'] as String,
        status: json['status'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        serviceCategory: json['serviceCategory'] as String?,
        partnerName: (json['partner'] as Map<String, dynamic>?)?['businessName'] as String?,
      );
}
