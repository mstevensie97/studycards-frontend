import 'package:flutter/material.dart';

import '../services/materia_service.dart';

/// HU001: formulario para crear una materia.
class CrearMateriaScreen extends StatefulWidget {
  const CrearMateriaScreen({super.key});

  @override
  State<CrearMateriaScreen> createState() => _CrearMateriaScreenState();
}

class _CrearMateriaScreenState extends State<CrearMateriaScreen> {
  static const _colores = <String, Color>{
    '#E53935': Color(0xFFE53935),
    '#FB8C00': Color(0xFFFB8C00),
    '#FDD835': Color(0xFFFDD835),
    '#43A047': Color(0xFF43A047),
    '#1E88E5': Color(0xFF1E88E5),
    '#8E24AA': Color(0xFF8E24AA),
  };

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _service = MateriaService();

  String? _colorSeleccionado;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final descripcion = _descripcionCtrl.text.trim();
      await _service.crearMateria(
        nombre: _nombreCtrl.text.trim(),
        descripcion: descripcion.isEmpty ? null : descripcion,
        color: _colorSeleccionado,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva materia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre de la materia es obligatorio'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Color (opcional)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _colores.entries.map((e) {
                  final seleccionado = _colorSeleccionado == e.key;
                  return GestureDetector(
                    onTap: () => setState(() =>
                    _colorSeleccionado = seleccionado ? null : e.key),
                    child: CircleAvatar(
                      backgroundColor: e.value,
                      radius: 20,
                      child: seleccionado
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}