import 'package:dio/dio.dart';
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
    try {
      final conversationId = await _ensureConversation(vehicleId: vehicleId);
      final response = await apiClient.dio.post(
        '/ai/conversations/$conversationId/messages',
        data: {'content': content, if (vehicleId != null) 'vehicleId': vehicleId},
      );
      return AiMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return AiMessage(
        role: 'assistant',
        content:
            "I'm running in offline demo mode right now, so I can't reach your real vehicle data — but once connected, I can answer questions about your service schedule, warranty, insurance, or inspection reports.\n\nThis is AI-generated guidance and not a substitute for professional mechanical, legal, or financial advice.",
      );
    }
  }
}
