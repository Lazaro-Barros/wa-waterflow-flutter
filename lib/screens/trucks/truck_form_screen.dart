import 'package:flutter/material.dart';
import '../../models/truck_model.dart';
import '../../services/truck_service.dart';

class TruckFormScreen extends StatefulWidget {
  final TruckModel? truck;

  const TruckFormScreen({
    super.key,
    this.truck,
  });

  @override
  State<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends State<TruckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TruckService _service = TruckService();

  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  bool get _isEditing => widget.truck != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.truck!;
      _plateController.text = t.plate;
      _capacityController.text = t.capacityLiters.toString();
      _descriptionController.text = t.description ?? '';
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A placa é obrigatória';
    }
    final normalized = value.toUpperCase().trim();
    final oldFormat = RegExp(r'^[A-Z]{3}-[0-9]{4}$');
    final newFormat = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    if (!oldFormat.hasMatch(normalized) && !newFormat.hasMatch(normalized)) {
      return 'Formato inválido. Use ABC-1234 ou ABC1D23';
    }
    return null;
  }

  String? _validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A capacidade é obrigatória';
    }
    final capacity = int.tryParse(value);
    if (capacity == null || capacity <= 0) {
      return 'A capacidade deve ser um número maior que zero';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plate = _plateController.text.trim().toUpperCase();
      final capacity = int.parse(_capacityController.text.trim());

      if (_isEditing) {
        final updates = <String, dynamic>{
          'plate': plate,
          'capacity_liters': capacity,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        };

        await _service.update(widget.truck!.id, updates);
      } else {
        final truck = TruckModel(
          id: '',
          plate: plate,
          capacityLiters: capacity,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _service.create(truck);
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
        title: Text(_isEditing ? 'Editar Caminhão' : 'Novo Caminhão'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  hintText: 'Ex: ABC-1234 ou ABC1D23',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                enabled: !_isLoading,
                validator: _validatePlate,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacidade (litros) *',
                  hintText: 'Ex: 5000',
                  prefixIcon: Icon(Icons.water_drop),
                ),
                enabled: !_isLoading,
                validator: _validateCapacity,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descrição do caminhão',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                enabled: !_isLoading,
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
}
