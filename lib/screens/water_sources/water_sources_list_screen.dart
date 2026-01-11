import 'package:flutter/material.dart';
import '../../models/water_source_model.dart';
import '../../models/water_source_list_response_model.dart';
import '../../services/water_source_service.dart';
import '../../widgets/water_source_status_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'water_source_detail_screen.dart';
import 'water_source_form_screen.dart';

class WaterSourcesListScreen extends StatefulWidget {
  const WaterSourcesListScreen({super.key});

  @override
  State<WaterSourcesListScreen> createState() => _WaterSourcesListScreenState();
}

class _WaterSourcesListScreenState extends State<WaterSourcesListScreen> {
  final WaterSourceService _service = WaterSourceService();
  final TextEditingController _searchController = TextEditingController();

  List<WaterSourceModel> _waterSources = [];
  PaginationInfo? _pagination;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageLimit = 10;

  // Filtros (valores temporários até aplicar)
  String? _tempSearchQuery;
  String? _tempStatusFilter;
  
  // Filtros aplicados
  String? _searchQuery;
  String? _statusFilter; // null = todos, "Ativo", "Inativo"

  @override
  void initState() {
    super.initState();
    _tempSearchQuery = _searchQuery;
    _tempStatusFilter = _statusFilter;
    _loadWaterSources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterSources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.list(
        name: _searchQuery,
        status: _statusFilter,
        page: _currentPage,
        limit: _pageLimit,
      );

      setState(() {
        _waterSources = response.data;
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
      _currentPage = 1;
    });
    _loadWaterSources();
  }

  void _clearFilters() {
    setState(() {
      _tempSearchQuery = null;
      _tempStatusFilter = null;
      _searchQuery = null;
      _statusFilter = null;
      _searchController.clear();
      _currentPage = 1;
    });
    _loadWaterSources();
  }

  bool _hasActiveFilters() {
    return _searchQuery != null || _statusFilter != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        label: const Text('Novo Manancial'),
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
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchFilter(),
                      const SizedBox(height: 16),
                      _buildStatusFilter(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando mananciais...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadWaterSources);
    }

    if (_waterSources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Nenhum manancial encontrado com os filtros aplicados'
                  : 'Nenhum manancial cadastrado',
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
                'Clique no botão "Novo Manancial" para criar um novo',
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
            DataColumn(label: Text('Localização')),
            DataColumn(label: Text('Coordenadas')),
            DataColumn(label: Text('Criado em')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _waterSources.map((waterSource) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    waterSource.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(WaterSourceStatusBadge(status: waterSource.status)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      waterSource.locationDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  waterSource.latitude != null && waterSource.longitude != null
                      ? Text(
                          '${waterSource.latitude!.toStringAsFixed(4)}, ${waterSource.longitude!.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : const Text('-'),
                ),
                DataCell(
                  Text(
                    _formatDate(waterSource.createdAt),
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
                        onPressed: () => _navigateToDetail(waterSource),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _navigateToEdit(waterSource),
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
                    _loadWaterSources();
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
                    _loadWaterSources();
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página ${_pagination!.page} de ${_pagination!.totalPages}',
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
                    _loadWaterSources();
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
                    _loadWaterSources();
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
      MaterialPageRoute(builder: (context) => const WaterSourceFormScreen()),
    );

    if (result == true) {
      _loadWaterSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manancial criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToDetail(WaterSourceModel waterSource) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WaterSourceDetailScreen(waterSourceId: waterSource.id),
      ),
    );

    if (result == true) {
      _loadWaterSources();
    }
  }

  void _navigateToEdit(WaterSourceModel waterSource) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaterSourceFormScreen(waterSource: waterSource),
      ),
    );

    if (result == true) {
      _loadWaterSources();
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
}
