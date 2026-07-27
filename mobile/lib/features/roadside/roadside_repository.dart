import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import 'roadside_model.dart';

class RoadsideRepository {
  RoadsideRepository(this.apiClient);

  final ApiClient apiClient;

  // NOTE: kept alongside serviceTypeLabel() below (rather than replaced)
  // because lib/features/partner/partner_jobs_screen.dart also indexes this
  // map directly and is outside this batch's scope.
  static const serviceTypes = <String, String>{
    'tow': 'Tow Truck',
    'jumpstart': 'Jump Start',
    'flat_tire': 'Flat Tire',
    'fuel_delivery': 'Fuel Delivery',
    'lockout': 'Lockout',
  };

  /// Service type IDs — stable, used as API values and lookup keys.
  static const serviceTypeKeys = <String>[
    'tow',
    'jumpstart',
    'flat_tire',
    'fuel_delivery',
    'lockout',
  ];

  static String serviceTypeLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'tow':
        return l10n.roadsideServiceTow;
      case 'jumpstart':
        return l10n.roadsideServiceJumpstart;
      case 'flat_tire':
        return l10n.roadsideServiceFlatTire;
      case 'fuel_delivery':
        return l10n.roadsideServiceFuelDelivery;
      case 'lockout':
        return l10n.roadsideServiceLockout;
      default:
        return key;
    }
  }

  Future<RoadsideRequestItem> createRequest({
    required String vehicleId,
    required String serviceType,
    required double lat,
    required double lng,
  }) async {
    final response = await apiClient.dio.post('/roadside/requests', data: {
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'location': {'lat': lat, 'lng': lng},
    });
    return RoadsideRequestItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoadsideRequestItem> track(String id) async {
    final response = await apiClient.dio.get('/roadside/requests/$id/track');
    return RoadsideRequestItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancel(String id) async {
    await apiClient.dio.post('/roadside/requests/$id/cancel');
  }

  Future<List<RoadsideRequestItem>> fetchMyRequests() async {
    final response = await apiClient.dio.get('/roadside/requests');
    return (response.data as List).map((e) => RoadsideRequestItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RoadsideRequestItem>> fetchAssignedToMe() async {
    final response = await apiClient.dio.get('/roadside/requests/assigned/mine');
    return (response.data as List).map((e) => RoadsideRequestItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await apiClient.dio.patch('/roadside/requests/$id/status', data: {'status': status});
  }
}
