import '../../core/api/api_client.dart';
import 'warranty_model.dart';

class WarrantyRepository {
  WarrantyRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<WarrantyPlan>> fetchPlans({String? vehicleId}) async {
    final response = await apiClient.dio.get('/warranty/plans', queryParameters: {
      if (vehicleId != null) 'vehicleId': vehicleId,
    });
    return (response.data as List).map((e) => WarrantyPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> purchasePolicy({required String planId, required String vehicleId}) async {
    await apiClient.dio.post('/warranty/policies', data: {'planId': planId, 'vehicleId': vehicleId});
  }

  Future<List<WarrantyPolicy>> fetchMyPolicies() async {
    final response = await apiClient.dio.get('/warranty/policies');
    return (response.data as List).map((e) => WarrantyPolicy.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitClaim({required String policyId, required String description}) async {
    await apiClient.dio.post('/warranty/claims', data: {'policyId': policyId, 'description': description});
  }
}
