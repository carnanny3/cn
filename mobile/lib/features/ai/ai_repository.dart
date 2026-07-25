import '../../core/api/api_client.dart';
import 'ai_message_model.dart';

class AiRepository {
  AiRepository(this.apiClient);

  final ApiClient apiClient;
  String? _conversationId;

  Future<String> _ensureConversation({String? vehicleId}) async {
    if (_conversationId != null) return _conversationId!;
    final response = await apiClient.dio.post('/ai/conversations', data: {
      if (vehicleId != null) 'vehicleId': vehicleId,
    });
    _conversationId = response.data['id'] as String;
    return _conversationId!;
  }

  Future<AiMessage> sendMessage(String content, {String? vehicleId}) async {
    final conversationId = await _ensureConversation(vehicleId: vehicleId);
    final response = await apiClient.dio.post(
      '/ai/conversations/$conversationId/messages',
      data: {'content': content, if (vehicleId != null) 'vehicleId': vehicleId},
    );
    return AiMessage.fromJson(response.data as Map<String, dynamic>);
  }
}
