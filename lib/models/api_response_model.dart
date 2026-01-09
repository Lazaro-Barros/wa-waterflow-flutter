class ApiResponseModel<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponseModel({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel<T>(
      success: json['success'] as bool,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] as String?,
    );
  }
}

