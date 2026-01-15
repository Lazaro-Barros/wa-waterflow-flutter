import 'region_model.dart';
import 'water_source_list_response_model.dart';

class ListRegionResponse {
  final List<RegionModel> data;
  final PaginationInfo pagination;

  ListRegionResponse({
    required this.data,
    required this.pagination,
  });

  factory ListRegionResponse.fromJson(Map<String, dynamic> json) {
    return ListRegionResponse(
      data: (json['data'] as List)
          .map((item) => RegionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}
