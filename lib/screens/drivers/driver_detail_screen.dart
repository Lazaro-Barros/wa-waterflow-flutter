import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../services/driver_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'driver_form_screen.dart';

class DriverDetailScreen extends StatefulWidget {
  final String driverId;

  const DriverDetailScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final DriverService _service = DriverService();
  DriverModel? _driver;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final driver = await _service.getById(widget.driverId);
      setState(() {
        _driver = driver;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_driver == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverFormScreen(driver: _driver),
      ),
    );

    if (result == true) {
      _loadDriver();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motorista atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Motorista'),
        actions: [
          if (_driver != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: _navigateToEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Carregando detalhes...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadDriver,
                )
              : _driver != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final driver = _driver!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informações',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.person,
                    'Nome',
                    driver.name,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.phone,
                    'Telefone',
                    driver.phone ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.local_shipping,
                    'Caminhão',
                    driver.truck?.plate ?? 'Não informado',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Metadados',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Criado em',
                    _formatDateTime(driver.createdAt),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.update_outlined,
                    'Atualizado em',
                    _formatDateTime(driver.updatedAt),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
