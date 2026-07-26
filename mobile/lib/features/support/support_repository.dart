import '../../core/api/api_client.dart';
import 'support_model.dart';

class SupportRepository {
  SupportRepository(this.apiClient);

  final ApiClient apiClient;

  static const categories = <String, String>{
    'booking': 'Booking issue',
    'billing': 'Billing / Payment',
    'inspection': 'Inspection',
    'account': 'Account',
    'other': 'Something else',
  };

  Future<List<SupportTicketSummary>> fetchMyTickets() async {
    final response = await apiClient.dio.get('/support/tickets');
    return (response.data as List).map((e) => SupportTicketSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SupportTicketDetail> createTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final response = await apiClient.dio.post('/support/tickets', data: {
      'category': category,
      'subject': subject,
      'message': message,
    });
    return SupportTicketDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SupportTicketDetail> fetchTicket(String id) async {
    final response = await apiClient.dio.get('/support/tickets/$id');
    return SupportTicketDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addMessage(String id, String content) async {
    await apiClient.dio.post('/support/tickets/$id/messages', data: {'content': content});
  }
}
