import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WaterFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de boas-vindas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo,',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Divider(),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        Icons.email_outlined,
                        'Email',
                        user.email,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.badge_outlined,
                        'Perfil',
                        user.role,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.business_outlined,
                        'Tenant ID',
                        user.tenantId.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Placeholder para conteúdo futuro
              Text(
                'Dashboard',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Conteúdo do sistema será implementado aqui.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: const Text('Deseja realmente sair do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = AuthService();
      await authService.logout();
      
      if (context.mounted) {
        // Voltar para a tela de login removendo todas as rotas anteriores
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}

