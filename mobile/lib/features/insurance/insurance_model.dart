class InsuranceQuote {
  InsuranceQuote({
    required this.id,
    this.premiumAmount,
    this.coverageType,
    this.excessAmount,
    required this.status,
    required this.providerName,
    required this.createdAt,
    required this.hasPolicy,
  });

  final String id;
  final double? premiumAmount;
  final String? coverageType;
  final double? excessAmount;
  final String status; // requested | quoted | expired
  final String providerName;
  final DateTime createdAt;
  final bool hasPolicy;

  factory InsuranceQuote.fromJson(Map<String, dynamic> json) => InsuranceQuote(
        id: json['id'] as String,
        premiumAmount: (json['premiumAmount'] as num?)?.toDouble(),
        coverageType: json['coverageType'] as String?,
        excessAmount: (json['excessAmount'] as num?)?.toDouble(),
        status: json['status'] as String,
        providerName: (json['provider'] as Map<String, dynamic>?)?['name'] as String? ?? 'Provider',
        createdAt: DateTime.parse(json['createdAt'] as String),
        hasPolicy: json['policy'] != null,
      );
}

class InsurancePolicy {
  InsurancePolicy({
    required this.id,
    required this.policyNumber,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.providerName,
  });

  final String id;
  final String policyNumber;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String providerName;

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    final quote = json['quote'] as Map<String, dynamic>?;
    return InsurancePolicy(
      id: json['id'] as String,
      policyNumber: json['policyNumber'] as String,
      status: json['status'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      providerName: (quote?['provider'] as Map<String, dynamic>?)?['name'] as String? ?? 'Provider',
    );
  }
}
