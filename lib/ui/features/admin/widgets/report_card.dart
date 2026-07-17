import 'package:flutter/material.dart';

import '../../../../data/models/report.dart';
import '../../../core/theme.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  IconData _areaIcon() {
    switch (report.area) {
      case ReportArea.sistema:
        return Icons.computer_outlined;

      case ReportArea.limpieza:
        return Icons.cleaning_services_outlined;

      case ReportArea.mantenimiento:
        return Icons.handyman_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  Color _statusColor() {
    switch (report.status) {
      case ReportStatus.pendiente:
        return AppTheme.pendingColor;

      case ReportStatus.enProceso:
        return AppTheme.inProgressColor;

      case ReportStatus.resuelto:
        return AppTheme.resolvedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status.displayName,
                      style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [

                  Icon(
                    _areaIcon(),
                    color: AppTheme.primaryColor,
                  ),

                  const SizedBox(width: 8),

                  Text(report.area?.displayName ?? "Sin área"),
                ],
              ),

              const SizedBox(height: 8),

              Text("Aula: ${report.classroom}"),

              Text("Edificio: ${report.building}"),

              Text("Reportó: ${report.reportedBy}"),

              const SizedBox(height: 12),

              Text(
                report.details,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              const Divider(),

              Row(
                children: [

                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    "${report.dateTime.day}/${report.dateTime.month}/${report.dateTime.year}",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}