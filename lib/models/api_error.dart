class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiError({
    required this.message,
    this.statusCode,
    this.code,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
    );
  }

  @override
  String toString() => message;
}
