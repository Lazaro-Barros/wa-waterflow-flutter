import 'package:flutter/material.dart';
import '../../models/region_model.dart';
import '../../models/water_source_model.dart';
import '../../services/region_service.dart';
import '../../services/water_source_service.dart';
import '../../widgets/water_source_status_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'region_form_screen.dart';

class RegionDetailScreen extends StatefulWidget {
  final String regionId;

  const RegionDetailScreen({
    super.key,
    required this.regionId,
  });

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> {
  final RegionService _service = RegionService();
  final WaterSourceService _waterSourceService = WaterSourceService();
  RegionModel? _region;
  WaterSourceModel? _waterSource;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRegion();
  }

  Future<void> _loadRegion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final region = await _service.getById(widget.regionId);
      setState(() {
        _region = region;
        _isLoading = false;
      });

      // Carregar manancial se houver
      if (region.waterSourceId != null) {
        try {
          final waterSource = await _waterSourceService.getById(region.waterSourceId!);
          setState(() {
            _waterSource = waterSource;
          });
        } catch (e) {
          // Ignorar erro ao carregar manancial
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_region == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionFormScreen(region: _region),
      ),
    );

    if (result == true) {
      _loadRegion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Região atualizada com sucesso!'),
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
        title: const Text('Detalhes da Região'),
        actions: [
          if (_region != null)
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
                  onRetry: _loadRegion,
                )
              : _region != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    final region = _region!;
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
                          region.name,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      WaterSourceStatusBadge(status: region.status),
                    ],
                  ),
                  if (region.description != null) ...[
                    const SizedBox(height: 16),
                    Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.description_outlined,
                      'Descrição',
                      region.description!,
                    ),
                  ],
                  if (region.statusReason != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.info_outline,
                      'Motivo do Status',
                      region.statusReason!,
                    ),
                  ],
                  if (region.notes != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.note_outlined,
                      'Notas',
                      region.notes!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de manancial
          if (region.waterSourceId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manancial',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.label_outline,
                      'Nome',
                      _waterSource?.name ?? 'Carregando...',
                    ),
                    if (_waterSource != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.location_on_outlined,
                        'Localização',
                        _waterSource!.locationDescription,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (region.waterSourceId != null) const SizedBox(height: 16),

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
                    _formatDateTime(region.createdAt),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.update_outlined,
                    'Atualizado em',
                    _formatDateTime(region.updatedAt),
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
