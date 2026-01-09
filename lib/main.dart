import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart' show AuthService, TokenExpiredException;
import 'models/auth_response_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação preferida (opcional, para web pode ser qualquer)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WaterFlowApp());
}

class WaterFlowApp extends StatelessWidget {
  const WaterFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Segue o tema do sistema
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const AuthWrapper(),
        '/home': (context) => const AuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  AuthResponseModel? _authResponse;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final hasToken = await _authService.isAuthenticated();
      
      if (hasToken) {
        // Verificar se o token ainda é válido e obter informações do usuário
        try {
          final user = await _authService.getCurrentUser();
          
          // Criar AuthResponseModel com token e usuário
          final token = await _authService.getToken();
          if (token != null) {
            setState(() {
              _authResponse = AuthResponseModel(
                token: token,
                user: user,
              );
              _isAuthenticated = true;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          if (e is TokenExpiredException) {
            // Token expirado
            await _handleTokenExpired(e.message);
            return;
          }
        }
      }
      
      // Não autenticado ou token inválido
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTokenExpired(String message) async {
    await _authService.logout();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });

      // Mostrar mensagem de token expirado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLoginSuccess(AuthResponseModel authResponse) {
    setState(() {
      _isAuthenticated = true;
      _authResponse = authResponse;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated && _authResponse != null) {
      return HomeScreen(user: _authResponse!.user);
    }

    return LoginScreen(onLoginSuccess: _handleLoginSuccess);
  }
}
