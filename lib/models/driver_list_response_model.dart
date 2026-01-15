import 'driver_model.dart';
import 'water_source_list_response_model.dart'; // Reutiliza PaginationInfo

class ListDriverResponse {
  final List<DriverModel> data;
  final PaginationInfo pagination;

  ListDriverResponse({
    required this.data,
    required this.pagination,
  });

  factory ListDriverResponse.fromJson(Map<String, dynamic> json) {
    return ListDriverResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => DriverModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
