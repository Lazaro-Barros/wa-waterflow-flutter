import 'water_source_model.dart';

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'total_pages': totalPages,
    };
  }
}

class ListWaterSourceResponse {
  final List<WaterSourceModel> data;
  final PaginationInfo pagination;

  ListWaterSourceResponse({
    required this.data,
    required this.pagination,
  });

  factory ListWaterSourceResponse.fromJson(Map<String, dynamic> json) {
    return ListWaterSourceResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => WaterSourceModel.fromJson(item as Map<String, dynamic>))
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
