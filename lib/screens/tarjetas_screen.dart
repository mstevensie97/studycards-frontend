import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/progreso.dart';
import '../models/tarjeta.dart';
import '../services/materia_service.dart' show ApiException;
import '../services/progreso_service.dart';
import '../services/tarjeta_service.dart';
import 'crear_tarjeta_screen.dart';

/// HU011: listado de las tarjetas de una materia.
/// Desde aquí también se crean tarjetas nuevas (HU008).
class TarjetasScreen extends StatefulWidget {
  final Materia materia;

  const TarjetasScreen({super.key, required this.materia});

  @override
  State<TarjetasScreen> createState() => _TarjetasScreenState();
}

class _TarjetasScreenState extends State<TarjetasScreen> {
  final _service = TarjetaService();
  final _progresoService = ProgresoService();
  late Future<ListadoTarjetas> _listado;
  late Future<Progreso> _progreso;

  @override
  void initState() {
    super.initState();
    _listado = _service.listarTarjetas(widget.materia.id);
    _progreso = _progresoService.consultar(widget.materia.id);
  }

  void _recargar() {
    setState(() {
      _listado = _service.listarTarjetas(widget.materia.id);
      _progreso = _progresoService.consultar(widget.materia.id);
    });
  }

  /// Abre el formulario: para crear (sin tarjeta) o para editar (HU009).
  Future<void> _abrirFormulario({Tarjeta? tarjeta}) async {
    final guardada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CrearTarjetaScreen(materia: widget.materia, tarjeta: tarjeta),
      ),
    );
    if (guardada == true && mounted) {
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tarjeta == null
              ? 'Tarjeta creada correctamente'
              : 'Tarjeta actualizada correctamente'),
        ),
      );
    }
  }

  /// HU010: eliminar una tarjeta, pidiendo confirmación antes.
  Future<void> _eliminar(Tarjeta tarjeta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 40),
        title: const Text('¿Eliminar tarjeta?'),
        content: Text(
          '"${tarjeta.pregunta}" se eliminará y no se podrá recuperar.',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return; // Canceló: no se borra nada.

    try {
      await _service.eliminarTarjeta(
        materiaId: widget.materia.id,
        tarjetaId: tarjeta.id,
      );
      if (!mounted) return;
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarjeta eliminada')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.materia.nombre)),
      body: FutureBuilder<ListadoTarjetas>(
        future: _listado,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _Mensaje(
              icono: Icons.cloud_off,
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).mensaje
                  : 'Ocurrió un error al cargar las tarjetas.',
              textoBoton: 'Reintentar',
              onPressed: _recargar,
            );
          }

          final listado = snapshot.data!;
          if (listado.tarjetas.isEmpty) {
            return const _Mensaje(
              icono: Icons.style_outlined,
              mensaje:
              'Esta materia aún no tiene tarjetas.\nUsa el botón + para crear la primera.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _listado;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              // +1 por el encabezado con el total
              itemCount: listado.tarjetas.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _ProgresoCard(
                    total: listado.total,
                    progreso: _progreso,
                  );
                }
                final tarjeta = listado.tarjetas[i - 1];
                return _TarjetaCard(
                  tarjeta: tarjeta,
                  onEditar: () => _abrirFormulario(tarjeta: tarjeta),
                  onEliminar: () => _eliminar(tarjeta),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Crear tarjeta',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// RQ-15: progreso de estudio de la materia (tarjetas estudiadas y
/// porcentaje marcado como "Aprendida"). Si no se puede cargar, solo se
/// muestra el total de tarjetas.
class _ProgresoCard extends StatelessWidget {
  final int total;
  final Future<Progreso> progreso;

  const _ProgresoCard({required this.total, required this.progreso});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Progreso>(
          future: progreso,
          builder: (context, snapshot) {
            final resumen = Text(
              '$total ${total == 1 ? 'tarjeta' : 'tarjetas'}',
              style: texto.titleSmall,
            );

            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  resumen,
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              );
            }

            final p = snapshot.data;
            if (snapshot.hasError || p == null) return resumen;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Tu progreso', style: texto.titleMedium)),
                    Text(
                      '${p.porcentajeAprendidas}%',
                      style: texto.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: p.porcentajeAprendidas / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 18),
                      label: Text('Aprendidas: ${p.aprendidas} de ${p.totalTarjetas}'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.school_outlined, size: 18),
                      label: Text('Estudiadas: ${p.estudiadas} de ${p.totalTarjetas}'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaCard extends StatelessWidget {
  final Tarjeta tarjeta;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaCard({
    required this.tarjeta,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tarjeta.pregunta, style: texto.titleMedium),
            const SizedBox(height: 8),
            Text(tarjeta.respuesta),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  avatar: Icon(
                    tarjeta.estaAprendida ? Icons.check_circle : Icons.schedule,
                    size: 18,
                  ),
                  label:
                  Text(tarjeta.estaAprendida ? 'Aprendida' : 'Por repasar'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEditar,
                  tooltip: 'Editar tarjeta',
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onEliminar,
                  tooltip: 'Eliminar tarjeta',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const _Mensaje({
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