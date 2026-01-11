import 'package:flutter/material.dart';
import '../../models/water_source_model.dart';
import '../../services/water_source_service.dart';

class WaterSourceFormScreen extends StatefulWidget {
  final WaterSourceModel? waterSource;

  const WaterSourceFormScreen({
    super.key,
    this.waterSource,
  });

  @override
  State<WaterSourceFormScreen> createState() => _WaterSourceFormScreenState();
}

class _WaterSourceFormScreenState extends State<WaterSourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final WaterSourceService _service = WaterSourceService();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _statusReasonController = TextEditingController();

  String _status = 'Ativo';
  bool _isLoading = false;

  bool get _isEditing => widget.waterSource != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final ws = widget.waterSource!;
      _nameController.text = ws.name;
      _addressController.text = ws.address ?? '';
      _locationDescriptionController.text = ws.locationDescription;
      _latitudeController.text = ws.latitude?.toString() ?? '';
      _longitudeController.text = ws.longitude?.toString() ?? '';
      _status = ws.status;
      _statusReasonController.text = ws.statusReason ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _locationDescriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _statusReasonController.dispose();
    super.dispose();
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
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          'location_description': _locationDescriptionController.text.trim(),
          'status': _status,
        };

        // Adicionar coordenadas se fornecidas
        if (_latitudeController.text.trim().isNotEmpty) {
          updates['latitude'] = double.parse(_latitudeController.text.trim());
        } else {
          updates['latitude'] = null;
        }

        if (_longitudeController.text.trim().isNotEmpty) {
          updates['longitude'] = double.parse(_longitudeController.text.trim());
        } else {
          updates['longitude'] = null;
        }

        // Status reason
        if (_status == 'Inativo') {
          updates['status_reason'] = _statusReasonController.text.trim();
        } else {
          updates['status_reason'] = null;
        }

        await _service.update(widget.waterSource!.id, updates);
      } else {
        // Criar
        final waterSource = WaterSourceModel(
          id: '',
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          locationDescription: _locationDescriptionController.text.trim(),
          latitude: _latitudeController.text.trim().isNotEmpty
              ? double.parse(_latitudeController.text.trim())
              : null,
          longitude: _longitudeController.text.trim().isNotEmpty
              ? double.parse(_longitudeController.text.trim())
              : null,
          status: _status,
          statusReason: _status == 'Inativo'
              ? _statusReasonController.text.trim()
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _service.create(waterSource);
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
        title: Text(_isEditing ? 'Editar Manancial' : 'Novo Manancial'),
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
                  hintText: 'Ex: Poço Boa Vista',
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

              // Endereço
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  hintText: 'Ex: Rua das Flores, 123',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Descrição da Localização
              TextFormField(
                controller: _locationDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Localização *',
                  hintText: 'Ex: Sítio Boa Vista, 300m após a escola rural',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A descrição da localização é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Coordenadas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '-90 a 90',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final lat = double.tryParse(value.trim());
                          if (lat == null) {
                            return 'Latitude inválida';
                          }
                          if (lat < -90 || lat > 90) {
                            return 'Latitude deve estar entre -90 e 90';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '-180 a 180',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final lon = double.tryParse(value.trim());
                          if (lon == null) {
                            return 'Longitude inválida';
                          }
                          if (lon < -180 || lon > 180) {
                            return 'Longitude deve estar entre -180 e 180';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
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
                    hintText: 'Ex: Manancial secou',
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

              // Botões
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
}
