import 'package:flutter/material.dart';
import '../../models/truck_model.dart';
import '../../models/water_source_list_response_model.dart'; // Para PaginationInfo
import '../../services/truck_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'truck_detail_screen.dart';
import 'truck_form_screen.dart';

class TrucksListScreen extends StatefulWidget {
  const TrucksListScreen({super.key});

  @override
  State<TrucksListScreen> createState() => _TrucksListScreenState();
}

class _TrucksListScreenState extends State<TrucksListScreen> {
  final TruckService _service = TruckService();
  final TextEditingController _searchController = TextEditingController();

  List<TruckModel> _trucks = [];
  PaginationInfo? _pagination;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageLimit = 10;

  String? _tempSearchQuery;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _tempSearchQuery = _searchQuery;
    _loadTrucks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrucks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.list(
        plate: _searchQuery,
        page: _currentPage,
        limit: _pageLimit,
      );

      setState(() {
        _trucks = response.data;
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
      _currentPage = 1;
    });
    _loadTrucks();
  }

  void _clearFilters() {
    setState(() {
      _tempSearchQuery = null;
      _searchQuery = null;
      _searchController.clear();
      _currentPage = 1;
    });
    _loadTrucks();
  }

  bool _hasActiveFilters() {
    return _searchQuery != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminhões'),
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(child: _buildBody()),
          if (_pagination != null) _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Novo Caminhão'),
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
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildSearchFilter()),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchFilter(),
                    ],
                  ),
            const SizedBox(height: 16),
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
          'Buscar por Placa',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por placa...',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando caminhões...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadTrucks);
    }

    if (_trucks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Nenhum caminhão encontrado com os filtros aplicados'
                  : 'Nenhum caminhão cadastrado',
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
                'Clique no botão "Novo Caminhão" para criar um novo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceVariant,
          ),
          columns: const [
            DataColumn(label: Text('Placa')),
            DataColumn(label: Text('Capacidade (L)')),
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Criado em')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _trucks.map((truck) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    truck.plate,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(Text(truck.capacityLiters.toString())),
                DataCell(
                  Text(
                    truck.description ?? '-',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(truck.createdAt),
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
                        onPressed: () => _navigateToDetail(truck),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _navigateToEdit(truck),
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
                    _loadTrucks();
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
                    _loadTrucks();
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
                    _loadTrucks();
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
                    _loadTrucks();
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
      MaterialPageRoute(builder: (context) => const TruckFormScreen()),
    );

    if (result == true) {
      _loadTrucks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caminhão criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToDetail(TruckModel truck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckDetailScreen(truckId: truck.id),
      ),
    );

    if (result == true) {
      _loadTrucks();
    }
  }

  void _navigateToEdit(TruckModel truck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckFormScreen(truck: truck),
      ),
    );

    if (result == true) {
      _loadTrucks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caminhão atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
