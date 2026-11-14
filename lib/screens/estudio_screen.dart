import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/sesion_estudio.dart';
import '../models/tarjeta.dart';
import '../services/estudio_service.dart';
import '../services/materia_service.dart' show ApiException;
import '../services/tarjeta_service.dart';
import '../theme/app_colors.dart';

/// HU012: sesión de estudio de una materia.
/// Muestra las tarjetas una por una: primero solo la pregunta, y la respuesta
/// se revela al tocar la tarjeta (con una animación de giro).
class EstudioScreen extends StatefulWidget {
  final Materia materia;

  const EstudioScreen({super.key, required this.materia});

  @override
  State<EstudioScreen> createState() => _EstudioScreenState();
}

class _EstudioScreenState extends State<EstudioScreen> {
  final _service = EstudioService();
  late Future<SesionEstudio> _sesion;

  @override
  void initState() {
    super.initState();
    _sesion = _service.iniciarSesion(widget.materia.id);
  }

  void _recargar() {
    setState(() {
      _sesion = _service.iniciarSesion(widget.materia.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estudiar · ${widget.materia.nombre}')),
      body: FutureBuilder<SesionEstudio>(
        future: _sesion,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _Mensaje(
              icono: Icons.cloud_off,
              mensaje: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).mensaje
                  : 'Ocurrió un error al iniciar la sesión.',
              textoBoton: 'Reintentar',
              onPressed: _recargar,
            );
          }

          final sesion = snapshot.data!;
          if (sesion.tarjetas.isEmpty) {
            return const _Mensaje(
              icono: Icons.style_outlined,
              mensaje:
              'Esta materia aún no tiene tarjetas para estudiar.\nCrea algunas y vuelve a intentarlo.',
            );
          }

          return _SesionView(
            key: ValueKey(sesion),
            sesion: sesion,
            onRepetir: _recargar,
          );
        },
      ),
    );
  }
}

class _SesionView extends StatefulWidget {
  final SesionEstudio sesion;
  final VoidCallback onRepetir;

  const _SesionView({super.key, required this.sesion, required this.onRepetir});

  @override
  State<_SesionView> createState() => _SesionViewState();
}

class _SesionViewState extends State<_SesionView> {
  int _indice = 0;
  bool _revelada = false;
  bool _terminada = false;

  final _tarjetaService = TarjetaService();
  // Resultado marcado en esta sesión: id de tarjeta -> "APRENDIDA" o "REPASAR".
  final Map<int, String> _resultados = {};
  bool _guardandoNivel = false;

  // RQ-16: momento en que apareció la tarjeta actual, para medir el tiempo.
  DateTime _inicioTarjeta = DateTime.now();

  int get _total => widget.sesion.tarjetas.length;

  void _anterior() {
    setState(() {
      _indice--;
      _revelada = false;
      _inicioTarjeta = DateTime.now();
    });
  }

  void _siguiente() {
    setState(() {
      if (_indice < _total - 1) {
        _indice++;
        _revelada = false;
        _inicioTarjeta = DateTime.now();
      } else {
        _terminada = true;
      }
    });
  }

  /// HU020 y HU021: marca la tarjeta actual y pasa a la siguiente.
  Future<void> _marcar(Tarjeta tarjeta, String nivel) async {
    final segundos = DateTime.now().difference(_inicioTarjeta).inSeconds;
    setState(() => _guardandoNivel = true);
    try {
      await _tarjetaService.marcarNivel(
        materiaId: widget.sesion.materiaId,
        tarjetaId: tarjeta.id,
        nivel: nivel,
        tiempoSegundos: segundos,
      );
      if (!mounted) return;
      _resultados[tarjeta.id] = nivel;
      setState(() => _guardandoNivel = false);
      _siguiente();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoNivel = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_terminada) {
      final aprendidas =
          _resultados.values.where((n) => n == 'APRENDIDA').length;
      final porRepasar = _resultados.values.where((n) => n == 'REPASAR').length;
      return _ResumenSesion(
        total: _total,
        aprendidas: aprendidas,
        porRepasar: porRepasar,
        onRepetir: widget.onRepetir,
        onVolver: () => Navigator.pop(context),
      );
    }

    final tarjeta = widget.sesion.tarjetas[_indice];
    final esUltima = _indice == _total - 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _AvisoModo(sesion: widget.sesion),
          const SizedBox(height: 12),
          Text('${_indice + 1} de $_total',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_indice + 1) / _total),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: GestureDetector(
                  onTap: () => setState(() => _revelada = !_revelada),
                  // La key hace que cada tarjeta nueva arranque mostrando
                  // la pregunta, sin animar el giro de vuelta.
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_indice),
                    tween: Tween<double>(begin: 0, end: _revelada ? 1 : 0),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    builder: (context, valor, _) {
                      final angulo = valor * math.pi;
                      final mostrandoRespuesta = angulo > math.pi / 2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angulo),
                        child: mostrandoRespuesta
                        // La cara trasera se gira otra vez para que el
                        // texto no se vea en espejo.
                            ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _Cara(
                            etiqueta: 'Respuesta',
                            texto: tarjeta.respuesta,
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                          ),
                        )
                            : _Cara(
                          etiqueta: 'Pregunta',
                          texto: tarjeta.pregunta,
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Text(
            _revelada
                ? 'Toca la tarjeta para volver a la pregunta'
                : 'Toca la tarjeta para ver la respuesta',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // HU020 y HU021: solo se puede marcar después de ver la respuesta.
          // Se reserva el espacio para que la pantalla no salte.
          Visibility(
            visible: _revelada,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.repasar,
                      side: const BorderSide(color: AppColors.repasar),
                    ),
                    onPressed: _guardandoNivel
                        ? null
                        : () => _marcar(tarjeta, 'REPASAR'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Repasar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aprendida,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _guardandoNivel
                        ? null
                        : () => _marcar(tarjeta, 'APRENDIDA'),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprendida'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _indice > 0 ? _anterior : null,
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _siguiente,
                  child: Text(esUltima ? 'Finalizar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// HU013: avisa qué tarjetas se están estudiando (vencidas o toda la materia).
class _AvisoModo extends StatelessWidget {
  final SesionEstudio sesion;

  const _AvisoModo({required this.sesion});

  @override
  Widget build(BuildContext context) {
    final vencidas = sesion.esDeVencidas;
    final total = sesion.tarjetas.length;
    final texto = vencidas
        ? 'Repasando $total ${total == 1 ? 'tarjeta vencida' : 'tarjetas vencidas'}'
        : 'No tienes tarjetas vencidas. Estudiando toda la materia en orden aleatorio';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(vencidas ? Icons.schedule : Icons.shuffle, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// RQ-14: resumen al terminar la sesión, con el porcentaje de aciertos y el
/// número de tarjetas correctas sobre el total repasado.
/// Acierto = tarjeta marcada como "Aprendida". Total repasado = tarjetas
/// marcadas en la sesión (las que se saltaron sin marcar no cuentan).
class _ResumenSesion extends StatelessWidget {
  final int total;
  final int aprendidas;
  final int porRepasar;
  final VoidCallback onRepetir;
  final VoidCallback onVolver;

  const _ResumenSesion({
    required this.total,
    required this.aprendidas,
    required this.porRepasar,
    required this.onRepetir,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final marcadas = aprendidas + porRepasar;
    final sinMarcar = total - marcadas;
    final porcentaje = marcadas == 0 ? 0 : (aprendidas * 100 / marcadas).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: color.primary),
            const SizedBox(height: 12),
            Text('¡Sesión completada!', style: texto.headlineSmall),
            const SizedBox(height: 24),
            if (marcadas == 0)
              const Text(
                'No marcaste ninguna tarjeta, así que no hay porcentaje de aciertos.',
                textAlign: TextAlign.center,
              )
            else ...[
              Text(
                '$porcentaje%',
                style: texto.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              Text('de aciertos', style: texto.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: LinearProgressIndicator(
                  value: aprendidas / marcadas,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$aprendidas de $marcadas '
                    '${marcadas == 1 ? 'tarjeta correcta' : 'tarjetas correctas'}',
                style: texto.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 18),
                    label: Text('Aprendidas: $aprendidas'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.refresh, size: 18),
                    label: Text('Por repasar: $porRepasar'),
                  ),
                  if (sinMarcar > 0)
                    Chip(
                      avatar: const Icon(Icons.remove_circle_outline, size: 18),
                      label: Text('Sin marcar: $sinMarcar'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: onRepetir, child: const Text('Estudiar de nuevo')),
            const SizedBox(height: 8),
            TextButton(onPressed: onVolver, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}

class _Cara extends StatelessWidget {
  final String etiqueta;
  final String texto;
  final Color color;

  const _Cara({required this.etiqueta, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(etiqueta.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 16),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
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
  final String? textoBotonSecundario;
  final VoidCallback? onPressedSecundario;

  const _Mensaje({
    required this.icono,
    required this.mensaje,
    this.textoBoton,
    this.onPressed,
    this.textoBotonSecundario,
    this.onPressedSecundario,
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
            if (textoBotonSecundario != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onPressedSecundario,
                child: Text(textoBotonSecundario!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}