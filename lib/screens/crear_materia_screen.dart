import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../services/materia_service.dart';

/// HU001 y HU002: formulario para crear una materia o, si se le pasa una
/// [materia], para editarla (con los datos ya cargados).
class CrearMateriaScreen extends StatefulWidget {
  final Materia? materia;

  const CrearMateriaScreen({super.key, this.materia});

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
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  final _service = MateriaService();

  String? _colorSeleccionado;
  bool _guardando = false;

  bool get _editando => widget.materia != null;

  /// Paletas de colores a mostrar. Si la materia que se edita tiene un color
  /// que no está en la paleta (por ejemplo creada desde Postman), se agrega
  /// para que no se pierda ni quede sin mostrar.
  Map<String, Color> get _coloresDisponibles {
    final mapa = Map<String, Color>.of(_colores);
    final actual = widget.materia?.color;
    if (actual != null &&
        !mapa.containsKey(actual) &&
        RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(actual)) {
      mapa[actual] = widget.materia!.colorFlutter;
    }
    return mapa;
  }

  @override
  void initState() {
    super.initState();
    final m = widget.materia;
    _nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: m?.descripcion ?? '');
    final color = m?.color;
    _colorSeleccionado = (color == null || color.isEmpty) ? null : color;
  }

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
      final nombre = _nombreCtrl.text.trim();
      final descripcionTexto = _descripcionCtrl.text.trim();
      final descripcion = descripcionTexto.isEmpty ? null : descripcionTexto;

      if (_editando) {
        await _service.actualizarMateria(
          id: widget.materia!.id,
          nombre: nombre,
          descripcion: descripcion,
          color: _colorSeleccionado,
        );
      } else {
        await _service.crearMateria(
          nombre: nombre,
          descripcion: descripcion,
          color: _colorSeleccionado,
        );
      }
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
      appBar: AppBar(
        title: Text(_editando ? 'Editar materia' : 'Nueva materia'),
      ),
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
                children: _coloresDisponibles.entries.map((e) {
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
                      : Text(_editando ? 'Guardar cambios' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}