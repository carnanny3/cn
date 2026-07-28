import '../../core/api/api_client.dart';
import 'user_model.dart';

class UserRepository {
  UserRepository(this.apiClient);

  final ApiClient apiClient;

  Future<UserProfile> fetchMe() async {
    final response = await apiClient.dio.get('/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateMe({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    final response = await apiClient.dio.patch('/users/me', data: {
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await apiClient.dio.patch('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Irreversible. Erases personal data server-side; the caller must sign out
  /// afterwards, since the account can no longer be signed into.
  Future<void> deleteAccount(String password) async {
    await apiClient.dio.delete('/users/me', data: {'password': password});
  }
}
