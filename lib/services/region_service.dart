import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/region_model.dart';
import '../models/region_list_response_model.dart';
import '../models/api_response_model.dart';
import 'auth_service.dart';

class RegionService {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'http://localhost:8080';

  // Criar região
  Future<RegionModel> create(RegionModel region) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/api/regions',
        body: region.toCreateJson(),
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
        throw Exception(apiResponse.error ?? 'Erro ao criar região');
      }

      return RegionModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Buscar região por ID
  Future<RegionModel> getById(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/api/regions/$id',
      );

      if (response.statusCode == 404) {
        throw Exception('Região não encontrada');
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
        throw Exception(apiResponse.error ?? 'Erro ao buscar região');
      }

      return RegionModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Atualizar região
  Future<RegionModel> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PUT',
        '/api/regions/$id',
        body: updates,
      );

      if (response.statusCode == 404) {
        throw Exception('Região não encontrada');
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
        throw Exception(apiResponse.error ?? 'Erro ao atualizar região');
      }

      return RegionModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Listar regiões
  Future<ListRegionResponse> list({
    String? status,
    String? name,
    String? waterSourceId,
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

      if (waterSourceId != null && waterSourceId.isNotEmpty) {
        queryParams['water_source_id'] = waterSourceId;
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/api/regions?$queryString';

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
        throw Exception(apiResponse.error ?? 'Erro ao listar regiões');
      }

      return ListRegionResponse.fromJson(apiResponse.data!);
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
