import 'package:flutter/material.dart';

import 'crear_materia_screen.dart';

/// Pantalla de inicio provisional.
/// En la HU006 se reemplaza por el listado real de materias.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _abrirFormulario(BuildContext context) async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearMateriaScreen()),
    );
    if (creada == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materia creada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyCards')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aquí aparecerá el listado de materias.\nUsa el botón + para crear una.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        tooltip: 'Crear materia',
        child: const Icon(Icons.add),
      ),
    );
  }
}