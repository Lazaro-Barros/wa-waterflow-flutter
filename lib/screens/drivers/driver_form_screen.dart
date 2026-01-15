import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../models/truck_model.dart';
import '../../services/driver_service.dart';
import '../../services/truck_service.dart';
import '../../widgets/loading_indicator.dart';

class DriverFormScreen extends StatefulWidget {
  final DriverModel? driver;

  const DriverFormScreen({
    super.key,
    this.driver,
  });

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DriverService _service = DriverService();
  final TruckService _truckService = TruckService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _truckSearchController = TextEditingController();
  final FocusNode _truckSearchFocusNode = FocusNode();

  String? _selectedTruckId;
  TruckModel? _selectedTruck;
  List<TruckModel> _truckSearchResults = [];
  bool _isLoading = false;
  bool _isSearchingTrucks = false;
  bool _showTruckResults = false;
  Timer? _searchDebounce;

  bool get _isEditing => widget.driver != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.driver!;
      _nameController.text = d.name;
      _phoneController.text = d.phone ?? '';
      _selectedTruckId = d.truckId;
      if (_selectedTruckId != null) {
        _loadSelectedTruck();
      }
    }
    _truckSearchController.addListener(_onTruckSearchChanged);
    _truckSearchFocusNode.addListener(() {
      if (!_truckSearchFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_truckSearchFocusNode.hasFocus) {
            setState(() {
              _showTruckResults = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _truckSearchController.dispose();
    _truckSearchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedTruck() async {
    if (_selectedTruckId == null) return;
    try {
      final truck = await _truckService.getById(_selectedTruckId!);
      setState(() {
        _selectedTruck = truck;
        _truckSearchController.text = truck.plate;
      });
    } catch (e) {
      setState(() {
        _selectedTruckId = null;
        _selectedTruck = null;
        _truckSearchController.clear();
      });
    }
  }

  void _onTruckSearchChanged() {
    final query = _truckSearchController.text.trim();
    _searchDebounce?.cancel();

    if (_selectedTruckId != null && query != _selectedTruck?.plate) {
      setState(() {
        _selectedTruckId = null;
        _selectedTruck = null;
      });
    }

    if (query.isEmpty) {
      setState(() {
        _truckSearchResults = [];
        _showTruckResults = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchTrucks(query);
    });
  }

  Future<void> _searchTrucks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _truckSearchResults = [];
        _showTruckResults = false;
      });
      return;
    }

    setState(() {
      _isSearchingTrucks = true;
      _showTruckResults = true;
    });

    try {
      final response = await _truckService.list(
        plate: query,
        limit: 10,
      );

      setState(() {
        _truckSearchResults = response.data;
        _isSearchingTrucks = false;
      });
    } catch (e) {
      setState(() {
        _truckSearchResults = [];
        _isSearchingTrucks = false;
      });
    }
  }

  void _selectTruck(TruckModel truck) {
    setState(() {
      _selectedTruckId = truck.id;
      _selectedTruck = truck;
      _truckSearchController.text = truck.plate;
      _showTruckResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearTruckSelection() {
    setState(() {
      _selectedTruckId = null;
      _selectedTruck = null;
      _truckSearchController.clear();
      _truckSearchResults = [];
      _showTruckResults = false;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTruckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um caminhão'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'truck_id': _selectedTruckId,
        };

        await _service.update(widget.driver!.id, updates);
      } else {
        final driver = DriverModel(
          id: '',
          truckId: _selectedTruckId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _service.create(driver);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Motorista' : 'Novo Motorista'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex: João Silva',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTruckSearchField(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Ex: (85) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? 'Salvar' : 'Criar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTruckSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _truckSearchController,
          focusNode: _truckSearchFocusNode,
          decoration: InputDecoration(
            labelText: 'Caminhão *',
            hintText: 'Buscar e selecionar um caminhão',
            prefixIcon: const Icon(Icons.local_shipping),
            suffixIcon: _selectedTruckId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearTruckSelection,
                  )
                : null,
          ),
          enabled: !_isLoading,
          validator: (value) {
            if (_selectedTruckId == null) {
              return 'Selecione um caminhão';
            }
            return null;
          },
          onTap: () {
            setState(() {
              _showTruckResults = true;
            });
            _searchTrucks(_truckSearchController.text);
          },
        ),
        if (_showTruckResults && _truckSearchFocusNode.hasFocus)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _isSearchingTrucks
                  ? const LoadingIndicator(message: 'Buscando caminhões...')
                  : _truckSearchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _truckSearchController.text.isEmpty
                                ? 'Digite para buscar caminhões'
                                : 'Nenhum caminhão encontrado',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _truckSearchResults.length,
                          itemBuilder: (context, index) {
                            final truck = _truckSearchResults[index];
                            return ListTile(
                              title: Text(truck.plate),
                              subtitle: Text(
                                'Capacidade: ${truck.capacityLiters}L',
                              ),
                              onTap: () => _selectTruck(truck),
                            );
                          },
                        ),
            ),
          ),
      ],
    );
  }
}
