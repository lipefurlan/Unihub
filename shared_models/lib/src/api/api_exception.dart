import 'package:dio/dio.dart';

/// Erro de API com mensagem amigável (em PT-BR, vinda do backend quando possível).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String, statusCode: error.response?.statusCode);
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const ApiException(
        'Não foi possível conectar ao servidor. Verifique se a API está rodando.',
      );
    }
    return ApiException('Erro inesperado. Tente novamente.', statusCode: error.response?.statusCode);
  }

  @override
  String toString() => message;
}
