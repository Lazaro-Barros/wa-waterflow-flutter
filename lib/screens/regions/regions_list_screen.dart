import 'package:flutter/material.dart';
import '../../models/region_model.dart';
import '../../models/water_source_model.dart';
import '../../models/water_source_list_response_model.dart';
import '../../services/region_service.dart';
import '../../services/water_source_service.dart';
import '../../widgets/water_source_status_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'region_detail_screen.dart';
import 'region_form_screen.dart';

class RegionsListScreen extends StatefulWidget {
  const RegionsListScreen({super.key});

  @override
  State<RegionsListScreen> createState() => _RegionsListScreenState();
}

class _RegionsListScreenState extends State<RegionsListScreen> {
  final RegionService _service = RegionService();
  final WaterSourceService _waterSourceService = WaterSourceService();
  final TextEditingController _searchController = TextEditingController();

  List<RegionModel> _regions = [];
  List<WaterSourceModel> _waterSources = [];
  PaginationInfo? _pagination;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageLimit = 10;

  // Filtros (valores temporários até aplicar)
  String? _tempSearchQuery;
  String? _tempStatusFilter;
  String? _tempWaterSourceFilter;
  
  // Filtros aplicados
  String? _searchQuery;
  String? _statusFilter; // null = todos, "Ativo", "Inativo"
  String? _waterSourceFilter; // null = todos, ID do manancial

  @override
  void initState() {
    super.initState();
    _tempSearchQuery = _searchQuery;
    _tempStatusFilter = _statusFilter;
    _tempWaterSourceFilter = _waterSourceFilter;
    _loadWaterSources();
    _loadRegions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterSources() async {
    try {
      final response = await _waterSourceService.list(
        status: 'Ativo', // Apenas mananciais ativos
        page: 1,
        limit: 100, // Carregar muitos para o dropdown
      );

      setState(() {
        _waterSources = response.data;
      });
    } catch (e) {
      // Não mostrar erro, apenas não carregar mananciais
    }
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.list(
        name: _searchQuery,
        status: _statusFilter,
        waterSourceId: _waterSourceFilter,
        page: _currentPage,
        limit: _pageLimit,
      );

      setState(() {
        _regions = response.data;
        _pagination = response.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _tempSearchQuery;
      _statusFilter = _tempStatusFilter;
      _waterSourceFilter = _tempWaterSourceFilter;
      _currentPage = 1;
    });
    _loadRegions();
  }

  void _clearFilters() {
    setState(() {
      _tempSearchQuery = null;
      _tempStatusFilter = null;
      _tempWaterSourceFilter = null;
      _searchQuery = null;
      _statusFilter = null;
      _waterSourceFilter = null;
      _searchController.clear();
      _currentPage = 1;
    });
    _loadRegions();
  }

  bool _hasActiveFilters() {
    return _searchQuery != null || _statusFilter != null || _waterSourceFilter != null;
  }

  String? _getWaterSourceName(String? waterSourceId) {
    if (waterSourceId == null) return null;
    final waterSource = _waterSources.firstWhere(
      (ws) => ws.id == waterSourceId,
      orElse: () => WaterSourceModel(
        id: '',
        name: 'Desconhecido',
        locationDescription: '',
        status: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return waterSource.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regiões'),
      ),
      body: Column(
        children: [
          // Seção de Filtros
          _buildFiltersSection(),

          // Conteúdo
          Expanded(child: _buildBody()),

          // Paginação (rodapé)
          if (_pagination != null) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nova Região'),
      ),
    );
  }

  Widget _buildFiltersSection() {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Filtros em Row (desktop) ou Column (mobile)
            isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildSearchFilter()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatusFilter()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildWaterSourceFilter()),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchFilter(),
                      const SizedBox(height: 16),
                      _buildStatusFilter(),
                      const SizedBox(height: 16),
                      _buildWaterSourceFilter(),
                    ],
                  ),

            const SizedBox(height: 16),

            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _hasActiveFilters() ? _clearFilters : null,
                  child: const Text('Limpar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Aplicar Filtros'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buscar',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por nome...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _tempSearchQuery = value.isEmpty ? null : value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _tempStatusFilter,
          decoration: InputDecoration(
            hintText: 'Todos',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: const [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Todos'),
            ),
            DropdownMenuItem(
              value: 'Ativo',
              child: Text('Ativo'),
            ),
            DropdownMenuItem(
              value: 'Inativo',
              child: Text('Inativo'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _tempStatusFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWaterSourceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manancial',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _tempWaterSourceFilter,
          decoration: InputDecoration(
            hintText: 'Todos',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos'),
            ),
            ..._waterSources.map((ws) => DropdownMenuItem(
                  value: ws.id,
                  child: Text(ws.name),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _tempWaterSourceFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando regiões...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadRegions);
    }

    if (_regions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Nenhuma região encontrada com os filtros aplicados'
                  : 'Nenhuma região cadastrada',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (_hasActiveFilters())
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Limpar filtros'),
              )
            else
              Text(
                'Clique no botão "Nova Região" para criar uma nova',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      );
    }

    // Tabela web-like
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceVariant,
          ),
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Manancial')),
            DataColumn(label: Text('Criado em')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _regions.map((region) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    region.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(WaterSourceStatusBadge(status: region.status)),
                DataCell(
                  Text(
                    _getWaterSourceName(region.waterSourceId) ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(region.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        tooltip: 'Ver detalhes',
                        onPressed: () => _navigateToDetail(region),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _navigateToEdit(region),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_pagination == null || _pagination!.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage = 1;
                    });
                    _loadRegions();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadRegions();
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página ${_pagination!.page} de ${_pagination!.totalPages} (${_pagination!.total} itens)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _pagination!.totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadRegions();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _pagination!.totalPages
                ? () {
                    setState(() {
                      _currentPage = _pagination!.totalPages;
                    });
                    _loadRegions();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegionFormScreen()),
    );

    if (result == true) {
      _loadRegions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Região criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToDetail(RegionModel region) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionDetailScreen(regionId: region.id),
      ),
    );

    if (result == true) {
      _loadRegions();
    }
  }

  void _navigateToEdit(RegionModel region) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionFormScreen(region: region),
      ),
    );

    if (result == true) {
      _loadRegions();
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
}
