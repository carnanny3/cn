class PartnerProfile {
  PartnerProfile({
    required this.id,
    required this.businessName,
    required this.partnerType,
    required this.status,
    this.contactPhone,
    this.contactEmail,
    this.tradeLicenseUrl,
    required this.ratingAvg,
    required this.services,
  });

  final String id;
  final String businessName;
  final String partnerType;
  final String status; // pending | verified | rejected | suspended
  final String? contactPhone;
  final String? contactEmail;
  final String? tradeLicenseUrl;
  final double ratingAvg;
  final List<PartnerServiceItem> services;

  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        partnerType: json['partnerType'] as String,
        status: json['status'] as String,
        contactPhone: json['contactPhone'] as String?,
        contactEmail: json['contactEmail'] as String?,
        tradeLicenseUrl: json['tradeLicenseUrl'] as String?,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        services: (json['services'] as List? ?? [])
            .map((e) => PartnerServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PartnerServiceItem {
  PartnerServiceItem({
    required this.id,
    required this.serviceCategory,
    required this.price,
    this.durationEstimateMinutes,
    required this.active,
  });

  final String id;
  final String serviceCategory;
  final double price;
  final int? durationEstimateMinutes;
  final bool active;

  factory PartnerServiceItem.fromJson(Map<String, dynamic> json) => PartnerServiceItem(
        id: json['id'] as String,
        serviceCategory: json['serviceCategory'] as String,
        price: (json['price'] as num).toDouble(),
        durationEstimateMinutes: json['durationEstimateMinutes'] as int?,
        active: json['active'] as bool? ?? true,
      );
}

class PartnerEarnings {
  PartnerEarnings({
    required this.completedJobCount,
    required this.grossAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.netPayout,
  });

  final int completedJobCount;
  final double grossAmount;
  final double commissionRate;
  final double commissionAmount;
  final double netPayout;

  factory PartnerEarnings.fromJson(Map<String, dynamic> json) => PartnerEarnings(
        completedJobCount: json['completedJobCount'] as int,
        grossAmount: (json['grossAmount'] as num).toDouble(),
        commissionRate: (json['commissionRate'] as num).toDouble(),
        commissionAmount: (json['commissionAmount'] as num).toDouble(),
        netPayout: (json['netPayout'] as num).toDouble(),
      );
}

class PartnerBookingJob {
  PartnerBookingJob({
    required this.id,
    required this.serviceCategory,
    required this.status,
    required this.scheduledAt,
    required this.totalAmount,
    this.customerName,
  });

  final String id;
  final String? serviceCategory;
  final String status;
  final DateTime scheduledAt;
  final double totalAmount;
  final String? customerName;

  factory PartnerBookingJob.fromJson(Map<String, dynamic> json) => PartnerBookingJob(
        id: json['id'] as String,
        serviceCategory: json['serviceCategory'] as String?,
        status: json['status'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        customerName: (json['customer'] as Map<String, dynamic>?)?['fullName'] as String?,
      );
}

class PartnerInspectionJob {
  PartnerInspectionJob({
    required this.id,
    required this.status,
    required this.scheduledAt,
    this.vehicleLabel,
    this.locationAddress,
  });

  final String id;
  final String status;
  final DateTime scheduledAt;
  final String? vehicleLabel;
  final String? locationAddress;

  factory PartnerInspectionJob.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return PartnerInspectionJob(
      id: json['id'] as String,
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      vehicleLabel: vehicle != null ? '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}' : null,
      locationAddress: json['locationAddress'] as String?,
    );
  }
}
