import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../services/materia_service.dart' show ApiException;
import '../services/tarjeta_service.dart';

/// HU008: formulario para crear una tarjeta (pregunta y respuesta)
/// dentro de una materia.
class CrearTarjetaScreen extends StatefulWidget {
  final Materia materia;

  const CrearTarjetaScreen({super.key, required this.materia});

  @override
  State<CrearTarjetaScreen> createState() => _CrearTarjetaScreenState();
}

class _CrearTarjetaScreenState extends State<CrearTarjetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preguntaCtrl = TextEditingController();
  final _respuestaCtrl = TextEditingController();
  final _service = TarjetaService();

  bool _guardando = false;

  @override
  void dispose() {
    _preguntaCtrl.dispose();
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await _service.crearTarjeta(
        materiaId: widget.materia.id,
        pregunta: _preguntaCtrl.text.trim(),
        respuesta: _respuestaCtrl.text.trim(),
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
      appBar: AppBar(title: Text('Nueva tarjeta · ${widget.materia.nombre}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _preguntaCtrl,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pregunta *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La pregunta es obligatoria'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _respuestaCtrl,
                maxLength: 1000,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Respuesta *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La respuesta es obligatoria'
                    : null,
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
                      : const Text('Guardar tarjeta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}