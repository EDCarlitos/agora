import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';

class AdminReportDetailDialog extends StatelessWidget {
  final Report report;

  const AdminReportDetailDialog({super.key, required this.report});

  static void show(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => AdminReportDetailDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('Reporte #${report.id}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              report.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Ubicación', value: '${report.building} - ${report.classroom}'),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.person_outline, label: 'Reportado por', value: report.reportedBy),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.access_time, label: 'Fecha y Hora', value: report.timeAgo),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                _StatusBadge(status: report.status, isDark: isDark),
              ],
            ),
            const Divider(height: 24),
            const Text('Descripción detallada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.details,
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

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case ReportStatus.pendiente:
        bg = isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFF3E0);
        fg = isDark ? Colors.amberAccent : const Color(0xFFD97706);
        break;
      case ReportStatus.enProceso:
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        break;
      case ReportStatus.resuelto:
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        break;
      case ReportStatus.rechazado:
        bg = isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFFE8E8);
        fg = isDark ? Colors.redAccent : const Color(0xFFDC2626);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
