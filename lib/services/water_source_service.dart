import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/water_source_model.dart';
import '../models/water_source_list_response_model.dart';
import '../models/api_response_model.dart';
import 'auth_service.dart';

class WaterSourceService {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'http://localhost:8080';

  // Criar manancial
  Future<WaterSourceModel> create(WaterSourceModel waterSource) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/api/water-sources',
        body: waterSource.toCreateJson(),
      );

      if (response.statusCode != 201) {
        _handleError(response);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'Erro ao criar manancial');
      }

      return WaterSourceModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Buscar manancial por ID
  Future<WaterSourceModel> getById(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/api/water-sources/$id',
      );

      if (response.statusCode == 404) {
        throw Exception('Manancial não encontrado');
      }

      if (response.statusCode != 200) {
        _handleError(response);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'Erro ao buscar manancial');
      }

      return WaterSourceModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Atualizar manancial
  Future<WaterSourceModel> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PUT',
        '/api/water-sources/$id',
        body: updates,
      );

      if (response.statusCode == 404) {
        throw Exception('Manancial não encontrado');
      }

      if (response.statusCode != 200) {
        _handleError(response);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'Erro ao atualizar manancial');
      }

      return WaterSourceModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Listar mananciais
  Future<ListWaterSourceResponse> list({
    String? status,
    String? name,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/api/water-sources?$queryString';

      final response = await _authService.authenticatedRequest(
        'GET',
        endpoint,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'Erro ao listar mananciais');
      }

      return ListWaterSourceResponse.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  void _handleError(http.Response response) {
    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<dynamic>.fromJson(
        jsonResponse,
        null,
      );
      throw Exception(apiResponse.error ?? 'Erro na requisição');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  }
}
