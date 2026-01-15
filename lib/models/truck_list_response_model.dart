import 'truck_model.dart';
import 'water_source_list_response_model.dart'; // Reutiliza PaginationInfo

class ListTruckResponse {
  final List<TruckModel> data;
  final PaginationInfo pagination;

  ListTruckResponse({
    required this.data,
    required this.pagination,
  });

  factory ListTruckResponse.fromJson(Map<String, dynamic> json) {
    return ListTruckResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => TruckModel.fromJson(item as Map<String, dynamic>))
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
