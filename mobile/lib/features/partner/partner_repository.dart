import '../../core/api/api_client.dart';
import 'partner_model.dart';

class PartnerRepository {
  PartnerRepository(this.apiClient);

  final ApiClient apiClient;

  static const checkpointCategories = <String>[
    'engine', 'transmission', 'chassis', 'brakes', 'suspension', 'steering',
    'electrical', 'battery', 'ac', 'tires', 'wheels', 'interior', 'exterior',
    'fluids', 'paint_thickness', 'obd', 'road_test',
  ];

  Future<PartnerProfile> fetchMyProfile() async {
    final response = await apiClient.dio.get('/partners/me');
    return PartnerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateMyProfile({String? businessName, String? contactPhone, String? contactEmail}) async {
    await apiClient.dio.patch('/partners/me', data: {
      if (businessName != null) 'businessName': businessName,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
    });
  }

  Future<void> addService({required String serviceCategory, required double price, int? durationEstimateMinutes}) async {
    await apiClient.dio.post('/partners/me/services', data: {
      'serviceCategory': serviceCategory,
      'price': price,
      if (durationEstimateMinutes != null) 'durationEstimateMinutes': durationEstimateMinutes,
    });
  }

  Future<void> updateService(String serviceId, {double? price, bool? active}) async {
    await apiClient.dio.patch('/partners/me/services/$serviceId', data: {
      if (price != null) 'price': price,
      if (active != null) 'active': active,
    });
  }

  Future<PartnerEarnings> fetchMyEarnings() async {
    final response = await apiClient.dio.get('/partners/me/earnings');
    return PartnerEarnings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PartnerBookingJob>> fetchMyBookingJobs() async {
    final response = await apiClient.dio.get('/bookings/partner/mine');
    return (response.data as List).map((e) => PartnerBookingJob.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await apiClient.dio.patch('/bookings/$bookingId/status', data: {'status': status});
  }

  Future<List<PartnerInspectionJob>> fetchMyInspectionJobs() async {
    final response = await apiClient.dio.get('/inspections/assigned/mine');
    return (response.data as List).map((e) => PartnerInspectionJob.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateInspectionStatus(String inspectionId, String status) async {
    await apiClient.dio.patch('/inspections/$inspectionId/status', data: {'status': status});
  }

  Future<void> submitCheckpoints(
    String inspectionId,
    List<Map<String, String>> checkpoints, {
    String? roadTestNotes,
  }) async {
    await apiClient.dio.post('/inspections/$inspectionId/checkpoints', data: {
      'checkpoints': checkpoints,
      if (roadTestNotes != null) 'roadTestNotes': roadTestNotes,
    });
  }
}
