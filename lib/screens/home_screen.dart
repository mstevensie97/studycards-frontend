import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../services/materia_service.dart';
import 'crear_materia_screen.dart';

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

  Future<void> _abrirFormulario() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearMateriaScreen()),
    );
    if (creada == true && mounted) {
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materia creada correctamente')),
      );
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
              itemBuilder: (context, i) => _MateriaCard(materia: materias[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Crear materia',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MateriaCard extends StatelessWidget {
  final Materia materia;

  const _MateriaCard({required this.materia});

  @override
  Widget build(BuildContext context) {
    final descripcion = materia.descripcion;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
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
                  ],
                ),
              ),
            ),
          ],
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