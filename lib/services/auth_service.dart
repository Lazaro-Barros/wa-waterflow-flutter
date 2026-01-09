import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../models/api_response_model.dart';
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080';
  final StorageService _storageService = StorageService();

  // Fazer login
  Future<AuthResponseModel> login(String emailOrCpf, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email_or_cpf': emailOrCpf,
          'password': password,
        }),
      );

      // Verificar status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Tentar parsear erro da API
        try {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          final apiResponse = ApiResponseModel<dynamic>.fromJson(
            jsonResponse,
            null,
          );
          throw Exception(apiResponse.error ?? 'Erro ao fazer login');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Erro ao fazer login: ${response.statusCode}');
        }
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'Erro ao fazer login');
      }

      final authResponse = AuthResponseModel.fromJson(apiResponse.data!);
      
      // Salvar token
      await _storageService.saveToken(authResponse.token);

      return authResponse;
    } on FormatException {
      throw Exception('Erro ao processar resposta do servidor');
    } on http.ClientException catch (e) {
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado: $e');
    }
  }

  // Fazer logout
  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // Verificar se está autenticado
  Future<bool> isAuthenticated() async {
    return await _storageService.hasToken();
  }

  // Obter token salvo
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  // Obter informações do usuário atual
  Future<UserModel> getCurrentUser() async {
    final response = await authenticatedRequest('GET', '/health_secured');
    
    if (response.statusCode != 200) {
      throw Exception('Erro ao obter informações do usuário');
    }

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    final userData = jsonResponse['user'] as Map<String, dynamic>;
    
    return UserModel.fromJson(userData);
  }

  // Verificar se token expirou (baseado na resposta da API)
  bool isTokenExpiredError(String errorMessage) {
    return errorMessage.contains('Token expired') ||
           errorMessage.contains('Please login again');
  }

  // Fazer requisição autenticada
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _storageService.getToken();
    
    if (token == null) {
      throw Exception('Token não encontrado');
    }

    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Método HTTP não suportado');
    }

    // Verificar se token expirou
    if (response.statusCode == 401) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponseModel<dynamic>.fromJson(
        jsonResponse,
        null,
      );
      
      if (apiResponse.error != null &&
          isTokenExpiredError(apiResponse.error!)) {
        // Token expirado - remover token
        await _storageService.deleteToken();
        throw TokenExpiredException(apiResponse.error!);
      }
    }

    return response;
  }
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}

