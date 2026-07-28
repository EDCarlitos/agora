import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';

class MockIncidencia {
  final String id;
  final String reporteId;
  final String titulo;
  final String edificio;
  final String aula;
  final String asignadoA;
  final String estado; // 'EN_PROCESO', 'FINALIZADA', 'REABIERTA'
  final DateTime fechaCreacion;
  final String descripcionResolucion;

  const MockIncidencia({
    required this.id,
    required this.reporteId,
    required this.titulo,
    required this.edificio,
    required this.aula,
    required this.asignadoA,
    required this.estado,
    required this.fechaCreacion,
    required this.descripcionResolucion,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(fechaCreacion);
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    return 'Hace ${difference.inDays} días';
  }
}

class AdminIncidenciaDetailDialog extends StatelessWidget {
  final MockIncidencia incidencia;

  const AdminIncidenciaDetailDialog({super.key, required this.incidencia});

  static void show(BuildContext context, MockIncidencia incidencia) {
    showDialog(
      context: context,
      builder: (ctx) => AdminIncidenciaDetailDialog(incidencia: incidencia),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.build_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('Incidencia #${incidencia.id}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              incidencia.titulo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.confirmation_number_outlined, label: 'Reporte Origen', value: '#${incidencia.reporteId}'),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Ubicación', value: '${incidencia.edificio} - ${incidencia.aula}'),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.engineering_outlined, label: 'Asignado a', value: incidencia.asignadoA),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.access_time, label: 'Fecha de Alta', value: incidencia.timeAgo),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                _IncidenciaStatusBadge(estado: incidencia.estado, isDark: isDark),
              ],
            ),
            const Divider(height: 24),
            const Text('Notas / Avance de Resolución:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                incidencia.descripcionResolucion,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AgoraPrimaryButton(
          text: 'Cerrar',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _IncidenciaStatusBadge extends StatelessWidget {
  final String estado;
  final bool isDark;

  const _IncidenciaStatusBadge({required this.estado, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String textLabel;

    switch (estado) {
      case 'EN_PROCESO':
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        textLabel = 'En Proceso';
        break;
      case 'FINALIZADA':
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        textLabel = 'Finalizada';
        break;
      case 'REABIERTA':
        bg = isDark ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF);
        fg = isDark ? Colors.purpleAccent : const Color(0xFF9333EA);
        textLabel = 'Reabierta';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        textLabel = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        textLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
