import '../../core/api/api_client.dart';
import 'listing_model.dart';

class ListingRepository {
  ListingRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<VehicleListingItem>> browseActive({String? make}) async {
    final response = await apiClient.dio.get('/listings', queryParameters: {
      if (make != null && make.isNotEmpty) 'make': make,
    });
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VehicleListingItem> getOne(String id) async {
    final response = await apiClient.dio.get('/listings/$id');
    return VehicleListingItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<VehicleListingItem>> compare(List<String> ids) async {
    final response = await apiClient.dio.get('/listings/compare', queryParameters: {'ids': ids.join(',')});
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VehicleListingItem>> fetchMyListings() async {
    final response = await apiClient.dio.get('/listings/mine');
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VehicleListingItem> createListing({
    String? vehicleId,
    required String make,
    required String model,
    required int year,
    int? mileageKm,
    required double askingPrice,
  }) async {
    final response = await apiClient.dio.post('/listings', data: {
      if (vehicleId != null) 'vehicleId': vehicleId,
      'make': make,
      'model': model,
      'year': year,
      if (mileageKm != null) 'mileageKm': mileageKm,
      'askingPrice': askingPrice,
    });
    return VehicleListingItem.fromJson(response.data as Map<String, dynamic>);
  }
}
