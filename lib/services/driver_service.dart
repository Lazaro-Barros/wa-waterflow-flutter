import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver_model.dart';
import '../models/driver_list_response_model.dart';
import '../models/api_response_model.dart';
import 'auth_service.dart';

class DriverService {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'http://localhost:8080';

  Future<DriverModel> create(DriverModel driver) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/api/drivers',
        body: driver.toCreateJson(),
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
        throw Exception(apiResponse.error ?? 'Erro ao criar motorista');
      }

      return DriverModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<DriverModel> getById(String id) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/api/drivers/$id',
      );

      if (response.statusCode == 404) {
        throw Exception('Motorista não encontrado');
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
        throw Exception(apiResponse.error ?? 'Erro ao buscar motorista');
      }

      return DriverModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<DriverModel> update(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PUT',
        '/api/drivers/$id',
        body: updates,
      );

      if (response.statusCode == 404) {
        throw Exception('Motorista não encontrado');
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
        throw Exception(apiResponse.error ?? 'Erro ao atualizar motorista');
      }

      return DriverModel.fromJson(apiResponse.data!);
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<ListDriverResponse> list({
    String? name,
    String? truckId,
    String? phone,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      if (truckId != null && truckId.isNotEmpty) {
        queryParams['truck_id'] = truckId;
      }

      if (phone != null && phone.isNotEmpty) {
        queryParams['phone'] = phone;
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/api/drivers?$queryString';

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
        throw Exception(apiResponse.error ?? 'Erro ao listar motoristas');
      }

      return ListDriverResponse.fromJson(apiResponse.data!);
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
