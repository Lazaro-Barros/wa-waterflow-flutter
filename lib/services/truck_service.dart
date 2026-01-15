import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/truck_model.dart';
import '../models/truck_list_response_model.dart';
import '../models/api_response_model.dart';
import 'auth_service.dart';

class TruckService {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'http://localhost:8080';

  Future<TruckModel> create(TruckModel truck) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/api/trucks',
        body: truck.toCreateJson(),
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
        throw Exception(apiResponse.error ?? 'Erro ao criar caminhão');
      }

      return TruckModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<TruckModel> getById(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/api/trucks/$id',
      );

      if (response.statusCode == 404) {
        throw Exception('Caminhão não encontrado');
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
        throw Exception(apiResponse.error ?? 'Erro ao buscar caminhão');
      }

      return TruckModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<TruckModel> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PUT',
        '/api/trucks/$id',
        body: updates,
      );

      if (response.statusCode == 404) {
        throw Exception('Caminhão não encontrado');
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
        throw Exception(apiResponse.error ?? 'Erro ao atualizar caminhão');
      }

      return TruckModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<ListTruckResponse> list({
    String? plate,
    String? name, // Busca por descrição
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (plate != null && plate.isNotEmpty) {
        queryParams['plate'] = plate;
      }

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/api/trucks?$queryString';

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
        throw Exception(apiResponse.error ?? 'Erro ao listar caminhões');
      }

      return ListTruckResponse.fromJson(apiResponse.data!);
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
