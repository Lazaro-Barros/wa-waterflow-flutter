import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../models/truck_model.dart';
import '../../models/water_source_list_response_model.dart'; // Para PaginationInfo
import '../../services/driver_service.dart';
import '../../services/truck_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'driver_detail_screen.dart';
import 'driver_form_screen.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  final DriverService _service = DriverService();
  final TruckService _truckService = TruckService();
  final TextEditingController _searchController = TextEditingController();

  List<DriverModel> _drivers = [];
  List<TruckModel> _trucks = [];
  PaginationInfo? _pagination;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageLimit = 10;

  String? _tempSearchQuery;
  String? _tempTruckFilter;
  String? _searchQuery;
  String? _truckFilter;

  @override
  void initState() {
    super.initState();
    _tempSearchQuery = _searchQuery;
    _tempTruckFilter = _truckFilter;
    _loadTrucks();
    _loadDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrucks() async {
    try {
      final response = await _truckService.list(
        page: 1,
        limit: 100,
      );
      setState(() {
        _trucks = response.data;
      });
    } catch (e) {
      // Não mostrar erro
    }
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.list(
        name: _searchQuery,
        truckId: _truckFilter,
        page: _currentPage,
        limit: _pageLimit,
      );

      setState(() {
        _drivers = response.data;
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
      _truckFilter = _tempTruckFilter;
      _currentPage = 1;
    });
    _loadDrivers();
  }

  void _clearFilters() {
    setState(() {
      _tempSearchQuery = null;
      _tempTruckFilter = null;
      _searchQuery = null;
      _truckFilter = null;
      _searchController.clear();
      _currentPage = 1;
    });
    _loadDrivers();
  }

  bool _hasActiveFilters() {
    return _searchQuery != null || _truckFilter != null;
  }

  String? _getTruckPlate(String? truckId) {
    if (truckId == null) return null;
    final truck = _trucks.firstWhere(
      (t) => t.id == truckId,
      orElse: () => TruckModel(
        id: '',
        plate: 'Desconhecido',
        capacityLiters: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return truck.plate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motoristas'),
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
        label: const Text('Novo Motorista'),
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
                      const SizedBox(width: 16),
                      Expanded(child: _buildTruckFilter()),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchFilter(),
                      const SizedBox(height: 16),
                      _buildTruckFilter(),
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

  Widget _buildTruckFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caminhão',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _tempTruckFilter,
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
            ..._trucks.map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(t.plate),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _tempTruckFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Carregando motoristas...');
    }

    if (_errorMessage != null) {
      return ErrorMessage(message: _errorMessage!, onRetry: _loadDrivers);
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Nenhum motorista encontrado com os filtros aplicados'
                  : 'Nenhum motorista cadastrado',
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
                'Clique no botão "Novo Motorista" para criar um novo',
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
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Telefone')),
            DataColumn(label: Text('Caminhão')),
            DataColumn(label: Text('Criado em')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _drivers.map((driver) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    driver.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    driver.phone ?? '-',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Text(
                    _getTruckPlate(driver.truckId) ?? '-',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(driver.createdAt),
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
                        onPressed: () => _navigateToDetail(driver),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _navigateToEdit(driver),
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
                    _loadDrivers();
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
                    _loadDrivers();
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
                    _loadDrivers();
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
                    _loadDrivers();
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
      MaterialPageRoute(builder: (context) => const DriverFormScreen()),
    );

    if (result == true) {
      _loadDrivers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motorista criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToDetail(DriverModel driver) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDetailScreen(driverId: driver.id),
      ),
    );

    if (result == true) {
      _loadDrivers();
    }
  }

  void _navigateToEdit(DriverModel driver) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverFormScreen(driver: driver),
      ),
    );

    if (result == true) {
      _loadDrivers();
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
}
