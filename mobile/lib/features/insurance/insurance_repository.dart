import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import 'insurance_model.dart';

class InsuranceRepository {
  InsuranceRepository(this.apiClient);

  final ApiClient apiClient;

  /// Coverage type IDs — stable, used as API values and lookup keys.
  static const coverageTypeKeys = <String>[
    'comprehensive',
    'third_party_liability',
  ];

  static String coverageTypeLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'comprehensive':
        return l10n.insuranceCoverageComprehensive;
      case 'third_party_liability':
        return l10n.insuranceCoverageThirdPartyLiability;
      default:
        return key;
    }
  }

  Future<void> requestQuote({required String vehicleId, String? coverageType}) async {
    await apiClient.dio.post('/insurance/quotes', data: {
      'vehicleId': vehicleId,
      if (coverageType != null) 'coverageType': coverageType,
    });
  }

  Future<List<InsuranceQuote>> fetchMyQuotes() async {
    final response = await apiClient.dio.get('/insurance/quotes');
    return (response.data as List).map((e) => InsuranceQuote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> purchasePolicy(String quoteId) async {
    await apiClient.dio.post('/insurance/policies', data: {'quoteId': quoteId});
  }

  Future<List<InsurancePolicy>> fetchMyPolicies() async {
    final response = await apiClient.dio.get('/insurance/policies');
    return (response.data as List).map((e) => InsurancePolicy.fromJson(e as Map<String, dynamic>)).toList();
  }
}
