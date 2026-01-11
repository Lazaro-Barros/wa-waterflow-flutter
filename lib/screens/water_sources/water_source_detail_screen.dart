import 'package:flutter/material.dart';
import '../../models/water_source_model.dart';
import '../../services/water_source_service.dart';
import '../../widgets/water_source_status_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'water_source_form_screen.dart';

class WaterSourceDetailScreen extends StatefulWidget {
  final String waterSourceId;

  const WaterSourceDetailScreen({
    super.key,
    required this.waterSourceId,
  });

  @override
  State<WaterSourceDetailScreen> createState() => _WaterSourceDetailScreenState();
}

class _WaterSourceDetailScreenState extends State<WaterSourceDetailScreen> {
  final WaterSourceService _service = WaterSourceService();
  WaterSourceModel? _waterSource;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWaterSource();
  }

  Future<void> _loadWaterSource() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final waterSource = await _service.getById(widget.waterSourceId);
      setState(() {
        _waterSource = waterSource;
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
    if (_waterSource == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaterSourceFormScreen(waterSource: _waterSource),
      ),
    );

    if (result == true) {
      _loadWaterSource();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manancial atualizado com sucesso!'),
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
        title: const Text('Detalhes do Manancial'),
        actions: [
          if (_waterSource != null)
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
                  onRetry: _loadWaterSource,
                )
              : _waterSource != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final waterSource = _waterSource!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de informações básicas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          waterSource.name,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      WaterSourceStatusBadge(status: waterSource.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (waterSource.statusReason != null) ...[
                    Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.info_outline,
                      'Motivo do Status',
                      waterSource.statusReason!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de localização
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Localização',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (waterSource.address != null) ...[
                    _buildInfoRow(
                      context,
                      Icons.home_outlined,
                      'Endereço',
                      waterSource.address!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    context,
                    Icons.description_outlined,
                    'Descrição da Localização',
                    waterSource.locationDescription,
                  ),
                  if (waterSource.latitude != null && waterSource.longitude != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.map_outlined,
                      'Coordenadas',
                      '${waterSource.latitude!.toStringAsFixed(6)}, ${waterSource.longitude!.toStringAsFixed(6)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de metadados
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
                    Icons.calendar_today_outlined,
                    'Criado em',
                    _formatDateTime(waterSource.createdAt),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.update_outlined,
                    'Atualizado em',
                    _formatDateTime(waterSource.updatedAt),
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
