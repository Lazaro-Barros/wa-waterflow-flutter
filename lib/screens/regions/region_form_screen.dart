import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/region_model.dart';
import '../../models/water_source_model.dart';
import '../../services/region_service.dart';
import '../../services/water_source_service.dart';

class RegionFormScreen extends StatefulWidget {
  final RegionModel? region;

  const RegionFormScreen({
    super.key,
    this.region,
  });

  @override
  State<RegionFormScreen> createState() => _RegionFormScreenState();
}

class _RegionFormScreenState extends State<RegionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RegionService _service = RegionService();
  final WaterSourceService _waterSourceService = WaterSourceService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _statusReasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _waterSourceSearchController = TextEditingController();
  final _waterSourceSearchFocusNode = FocusNode();

  String _status = 'Ativo';
  String? _selectedWaterSourceId;
  WaterSourceModel? _selectedWaterSource;
  List<WaterSourceModel> _waterSourceSearchResults = [];
  bool _isLoading = false;
  bool _isSearchingWaterSources = false;
  bool _showWaterSourceResults = false;
  Timer? _searchDebounce;

  bool get _isEditing => widget.region != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final r = widget.region!;
      _nameController.text = r.name;
      _descriptionController.text = r.description ?? '';
      _statusReasonController.text = r.statusReason ?? '';
      _notesController.text = r.notes ?? '';
      _status = r.status;
      _selectedWaterSourceId = r.waterSourceId;
      if (_selectedWaterSourceId != null) {
        _loadSelectedWaterSource();
      }
    }
    _waterSourceSearchController.addListener(_onWaterSourceSearchChanged);
    _waterSourceSearchFocusNode.addListener(() {
      if (!_waterSourceSearchFocusNode.hasFocus) {
        // Fechar lista quando perde o foco (após um pequeno delay para permitir clique nos itens)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_waterSourceSearchFocusNode.hasFocus) {
            setState(() {
              _showWaterSourceResults = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _statusReasonController.dispose();
    _notesController.dispose();
    _waterSourceSearchController.dispose();
    _waterSourceSearchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedWaterSource() async {
    if (_selectedWaterSourceId == null) return;

    try {
      final waterSource = await _waterSourceService.getById(_selectedWaterSourceId!);
      setState(() {
        _selectedWaterSource = waterSource;
        _waterSourceSearchController.text = waterSource.name;
      });
    } catch (e) {
      // Ignorar erro
    }
  }

  void _onWaterSourceSearchChanged() {
    final query = _waterSourceSearchController.text.trim();

    // Cancelar busca anterior
    _searchDebounce?.cancel();

    // Se já tem um manancial selecionado e o texto mudou, limpar seleção
    if (_selectedWaterSourceId != null && query != _selectedWaterSource?.name) {
      setState(() {
        _selectedWaterSourceId = null;
        _selectedWaterSource = null;
      });
    }

    // Se o campo está vazio, não mostrar resultados
    if (query.isEmpty) {
      setState(() {
        _waterSourceSearchResults = [];
        _showWaterSourceResults = false;
      });
      return;
    }

    // Debounce de 300ms
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchWaterSources(query);
    });
  }

  Future<void> _searchWaterSources(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _waterSourceSearchResults = [];
        _showWaterSourceResults = false;
      });
      return;
    }

    setState(() {
      _isSearchingWaterSources = true;
      _showWaterSourceResults = true;
    });

    try {
      final response = await _waterSourceService.list(
        name: query,
        status: 'Ativo',
        page: 1,
        limit: 10, // Limitar a 10 resultados
      );

      setState(() {
        _waterSourceSearchResults = response.data;
        _isSearchingWaterSources = false;
      });
    } catch (e) {
      setState(() {
        _waterSourceSearchResults = [];
        _isSearchingWaterSources = false;
      });
    }
  }

  void _selectWaterSource(WaterSourceModel waterSource) {
    setState(() {
      _selectedWaterSourceId = waterSource.id;
      _selectedWaterSource = waterSource;
      _waterSourceSearchController.text = waterSource.name;
      _showWaterSourceResults = false;
    });
    // Remover foco do campo
    FocusScope.of(context).unfocus();
  }

  void _clearWaterSourceSelection() {
    setState(() {
      _selectedWaterSourceId = null;
      _selectedWaterSource = null;
      _waterSourceSearchController.clear();
      _waterSourceSearchResults = [];
      _showWaterSourceResults = false;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Atualizar
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'status': _status,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'water_source_id': _selectedWaterSourceId,
        };

        // Status reason
        if (_status == 'Inativo') {
          updates['status_reason'] = _statusReasonController.text.trim();
        } else {
          updates['status_reason'] = null;
        }

        await _service.update(widget.region!.id, updates);
      } else {
        // Criar
        final region = RegionModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          status: _status,
          statusReason: _status == 'Inativo'
              ? _statusReasonController.text.trim()
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          waterSourceId: _selectedWaterSourceId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _service.create(region);
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
        title: Text(_isEditing ? 'Editar Região' : 'Nova Região'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex: Região Norte',
                  prefixIcon: Icon(Icons.label_outline),
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

              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descrição da região',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Manancial - Campo de busca com autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _waterSourceSearchController,
                    focusNode: _waterSourceSearchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Manancial',
                      hintText: _selectedWaterSourceId == null
                          ? 'Digite o nome do manancial...'
                          : null,
                      prefixIcon: const Icon(Icons.water_drop),
                      suffixIcon: _selectedWaterSourceId != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearWaterSourceSelection,
                              tooltip: 'Limpar seleção',
                            )
                          : _isSearchingWaterSources
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                    ),
                    enabled: !_isLoading,
                    onTap: () {
                      if (_waterSourceSearchController.text.isNotEmpty) {
                        setState(() {
                          _showWaterSourceResults = true;
                        });
                      }
                    },
                    onChanged: (value) {
                      // O listener já trata a busca
                    },
                  ),
                  // Lista de resultados
                  if (_showWaterSourceResults) _buildWaterSourceResults(),
                ],
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Ativo',
                    child: Text('Ativo'),
                  ),
                  DropdownMenuItem(
                    value: 'Inativo',
                    child: Text('Inativo'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Status Reason (aparece apenas quando Inativo)
              if (_status == 'Inativo') ...[
                TextFormField(
                  controller: _statusReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo do Status *',
                    hintText: 'Ex: Região desativada temporariamente',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (_status == 'Inativo' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'O motivo do status é obrigatório quando o status é Inativo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Notas
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Notas adicionais sobre a região',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              // Botões
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

  Widget _buildWaterSourceResults() {
    if (_isSearchingWaterSources) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_waterSourceSearchResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Nenhum manancial encontrado',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _waterSourceSearchResults.length,
        itemBuilder: (context, index) {
          final waterSource = _waterSourceSearchResults[index];
          return ListTile(
            leading: const Icon(Icons.water_drop),
            title: Text(waterSource.name),
            subtitle: waterSource.locationDescription.isNotEmpty
                ? Text(
                    waterSource.locationDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _selectWaterSource(waterSource),
            dense: true,
          );
        },
      ),
    );
  }
}
