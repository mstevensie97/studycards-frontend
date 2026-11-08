import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/tarjeta.dart';
import '../services/materia_service.dart' show ApiException;
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
  late Future<ListadoTarjetas> _listado;

  @override
  void initState() {
    super.initState();
    _listado = _service.listarTarjetas(widget.materia.id);
  }

  void _recargar() {
    setState(() {
      _listado = _service.listarTarjetas(widget.materia.id);
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
                  return Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '${listado.total} ${listado.total == 1 ? 'tarjeta' : 'tarjetas'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                }
                final tarjeta = listado.tarjetas[i - 1];
                return _TarjetaCard(
                  tarjeta: tarjeta,
                  onEditar: () => _abrirFormulario(tarjeta: tarjeta),
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

class _TarjetaCard extends StatelessWidget {
  final Tarjeta tarjeta;
  final VoidCallback onEditar;

  const _TarjetaCard({required this.tarjeta, required this.onEditar});

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