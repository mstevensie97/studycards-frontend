import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../services/materia_service.dart';
import 'crear_materia_screen.dart';
import 'estudio_screen.dart';
import 'tarjetas_screen.dart';

/// HU006: listado de materias con su total de tarjetas y las pendientes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MateriaService();
  late Future<List<Materia>> _materias;

  @override
  void initState() {
    super.initState();
    _materias = _service.listarMaterias();
  }

  void _recargar() {
    setState(() {
      _materias = _service.listarMaterias();
    });
  }

  /// Abre el formulario: para crear (sin materia) o para editar (HU002).
  Future<void> _abrirFormulario({Materia? materia}) async {
    final guardada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrearMateriaScreen(materia: materia)),
    );
    if (guardada == true && mounted) {
      _recargar();
      _mostrarMensaje(materia == null
          ? 'Materia creada correctamente'
          : 'Materia actualizada correctamente');
    }
  }

  /// HU011: abre las tarjetas de una materia. Al volver se recarga la lista
  /// para que los contadores (total y pendientes) queden al día.
  Future<void> _abrirTarjetas(Materia materia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TarjetasScreen(materia: materia)),
    );
    if (mounted) _recargar();
  }

  /// HU012: inicia una sesión de estudio de la materia.
  /// Al volver se recarga la lista: marcar tarjetas cambia los pendientes.
  Future<void> _abrirEstudio(Materia materia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EstudioScreen(materia: materia)),
    );
    if (mounted) _recargar();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// HU003, HU004 y HU005: eliminar una materia.
  Future<void> _eliminar(Materia materia) async {
    try {
      // Primer intento, sin confirmar.
      final advertencia = await _service.eliminarMateria(materia.id);

      if (advertencia == null) {
        // La materia no tenía tarjetas: se eliminó directamente (HU003).
        if (!mounted) return;
        _recargar();
        _mostrarMensaje('Materia "${materia.nombre}" eliminada');
        return;
      }

      // La materia tiene tarjetas: se pide confirmación (HU004).
      if (!mounted) return;
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, size: 40),
          title: const Text('¿Eliminar materia?'),
          content: Text(
            '"${materia.nombre}" tiene ${advertencia.totalTarjetas} '
                '${advertencia.totalTarjetas == 1 ? 'tarjeta' : 'tarjetas'}. '
                'Si continúas, se eliminarán también y no se podrán recuperar.',
          ),
          actions: [
            // HU005: cancelar no borra nada.
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar todo'),
            ),
          ],
        ),
      );

      if (confirmado != true) return; // Canceló: la materia queda intacta.

      await _service.eliminarMateria(materia.id, confirmar: true);
      if (!mounted) return;
      _recargar();
      _mostrarMensaje('Materia "${materia.nombre}" eliminada');
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.mensaje);
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StudyCards')),
      body: FutureBuilder<List<Materia>>(
        future: _materias,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MensajeConBoton(
              icono: Icons.cloud_off,
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).mensaje
                  : 'Ocurrió un error al cargar las materias.',
              textoBoton: 'Reintentar',
              onPressed: _recargar,
            );
          }

          final materias = snapshot.data ?? [];
          if (materias.isEmpty) {
            return const _MensajeConBoton(
              icono: Icons.menu_book_outlined,
              mensaje: 'Aún no tienes materias.\nUsa el botón + para crear la primera.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _materias;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: materias.length,
              itemBuilder: (context, i) => _MateriaCard(
                materia: materias[i],
                onAbrir: () => _abrirTarjetas(materias[i]),
                onEstudiar: () => _abrirEstudio(materias[i]),
                onEditar: () => _abrirFormulario(materia: materias[i]),
                onEliminar: () => _eliminar(materias[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Crear materia',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MateriaCard extends StatelessWidget {
  final Materia materia;
  final VoidCallback onAbrir;
  final VoidCallback onEstudiar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _MateriaCard({
    required this.materia,
    required this.onAbrir,
    required this.onEstudiar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = materia.descripcion;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onAbrir,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: materia.colorFlutter),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (descripcion != null && descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(descripcion),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.style, size: 18),
                            label: Text('${materia.totalTarjetas} tarjetas'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text('${materia.tarjetasPendientes} pendientes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onEstudiar,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Estudiar'),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onEditar,
                tooltip: 'Editar materia',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onEliminar,
                tooltip: 'Eliminar materia',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MensajeConBoton extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const _MensajeConBoton({
    required this.icono,
    required this.mensaje,
    this.textoBoton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            if (textoBoton != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(textoBoton!)),
            ],
          ],
        ),
      ),
    );
  }
}