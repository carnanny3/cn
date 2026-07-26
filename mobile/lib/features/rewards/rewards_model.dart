class RewardsTransactionItem {
  RewardsTransactionItem({required this.points, required this.reason, required this.createdAt});

  final int points;
  final String reason;
  final DateTime createdAt;

  factory RewardsTransactionItem.fromJson(Map<String, dynamic> json) => RewardsTransactionItem(
        points: json['points'] as int,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ReferralItem {
  ReferralItem({required this.status, this.referredUserName});

  final String status;
  final String? referredUserName;

  factory ReferralItem.fromJson(Map<String, dynamic> json) => ReferralItem(
        status: json['status'] as String,
        referredUserName: (json['referredUser'] as Map<String, dynamic>?)?['fullName'] as String?,
      );
}

class RewardsSummary {
  RewardsSummary({
    required this.pointsBalance,
    required this.referralCode,
    required this.transactions,
    required this.referrals,
  });

  final int pointsBalance;
  final String referralCode;
  final List<RewardsTransactionItem> transactions;
  final List<ReferralItem> referrals;

  factory RewardsSummary.fromJson(Map<String, dynamic> json) => RewardsSummary(
        pointsBalance: json['pointsBalance'] as int,
        referralCode: json['referralCode'] as String,
        transactions: (json['transactions'] as List)
            .map((e) => RewardsTransactionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        referrals: (json['referrals'] as List)
            .map((e) => ReferralItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
