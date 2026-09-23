import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/upload_file.dart';
import 'logbook_models.dart';

class LogbookRepository {
  LogbookRepository(this.apiClient);

  final ApiClient apiClient;

  String _v(String vehicleId) => '/vehicles/$vehicleId';

  // ---------- Records ----------

  Future<List<LogRecord>> fetchRecords(String vehicleId) async {
    final response = await apiClient.dio.get('${_v(vehicleId)}/records');
    return (response.data as List).map((e) => LogRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LogRecord> saveRecord(String vehicleId, Map<String, dynamic> body, {String? recordId}) async {
    final response = recordId == null
        ? await apiClient.dio.post('${_v(vehicleId)}/records', data: body)
        : await apiClient.dio.patch('${_v(vehicleId)}/records/$recordId', data: body);
    return LogRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecord(String vehicleId, String recordId) =>
      apiClient.dio.delete('${_v(vehicleId)}/records/$recordId');

  Future<RecordPhoto> uploadRecordPhoto(String vehicleId, String recordId, UploadFile file) async {
    final response = await apiClient.dio.post(
      '${_v(vehicleId)}/records/$recordId/photos',
      data: FormData.fromMap({'file': file.toMultipart()}),
      options: uploadOptions(),
    );
    return RecordPhoto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecordPhoto(String vehicleId, String recordId, String photoId) =>
      apiClient.dio.delete('${_v(vehicleId)}/records/$recordId/photos/$photoId');

  // ---------- Fuel ----------

  Future<FuelLog> fetchFuel(String vehicleId) async {
    final response = await apiClient.dio.get('${_v(vehicleId)}/fuel');
    return FuelLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> saveFuel(String vehicleId, Map<String, dynamic> body, {String? entryId}) async {
    if (entryId == null) {
      await apiClient.dio.post('${_v(vehicleId)}/fuel', data: body);
    } else {
      await apiClient.dio.patch('${_v(vehicleId)}/fuel/$entryId', data: body);
    }
  }

  Future<void> deleteFuel(String vehicleId, String entryId) => apiClient.dio.delete('${_v(vehicleId)}/fuel/$entryId');

  // ---------- Reminders ----------

  Future<List<Reminder>> fetchReminders(String vehicleId) async {
    final response = await apiClient.dio.get('${_v(vehicleId)}/reminders');
    return (response.data as List).map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveReminder(String vehicleId, Map<String, dynamic> body, {String? reminderId}) async {
    if (reminderId == null) {
      await apiClient.dio.post('${_v(vehicleId)}/reminders', data: body);
    } else {
      await apiClient.dio.patch('${_v(vehicleId)}/reminders/$reminderId', data: body);
    }
  }

  /// Returns true when a repeating reminder scheduled its next occurrence.
  Future<bool> completeReminder(String vehicleId, String reminderId) async {
    final response = await apiClient.dio.post('${_v(vehicleId)}/reminders/$reminderId/complete');
    return (response.data as Map<String, dynamic>)['next'] != null;
  }

  Future<void> deleteReminder(String vehicleId, String reminderId) =>
      apiClient.dio.delete('${_v(vehicleId)}/reminders/$reminderId');

  /// Open reminders that need action, across every vehicle the user owns.
  Future<List<Reminder>> fetchAttention() async {
    final response = await apiClient.dio.get('/logbook/attention');
    return (response.data as List).map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------- Summary & export ----------

  Future<LogbookSummary> fetchSummary(String vehicleId) async {
    final response = await apiClient.dio.get('${_v(vehicleId)}/logbook-summary');
    return LogbookSummary.fromJson(response.data as Map<String, dynamic>);
  }

  /// CSV bytes plus the server-chosen filename. [kind] is 'records' or 'fuel'.
  Future<({String filename, Uint8List bytes})> exportCsv(String vehicleId, String kind) async {
    final response = await apiClient.dio.get<List<int>>(
      '${_v(vehicleId)}/export.csv',
      queryParameters: {'kind': kind},
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = response.headers.value('content-disposition') ?? '';
    final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
    return (
      filename: match?.group(1) ?? '$kind.csv',
      bytes: Uint8List.fromList(response.data ?? utf8.encode('')),
    );
  }

  // ---------- Co-owners ----------

  Future<List<CoOwner>> fetchOwners(String vehicleId) async {
    final response = await apiClient.dio.get('${_v(vehicleId)}/owners');
    return (response.data as List).map((e) => CoOwner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addCoOwner(String vehicleId, String email) =>
      apiClient.dio.post('${_v(vehicleId)}/owners', data: {'email': email});

  Future<void> removeOwner(String vehicleId, String userId) =>
      apiClient.dio.delete('${_v(vehicleId)}/owners/$userId');
}
