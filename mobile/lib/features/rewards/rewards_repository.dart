import '../../core/api/api_client.dart';
import 'rewards_model.dart';

class RewardsRepository {
  RewardsRepository(this.apiClient);

  final ApiClient apiClient;

  Future<RewardsSummary> fetchMyRewards() async {
    final response = await apiClient.dio.get('/rewards/me');
    return RewardsSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
