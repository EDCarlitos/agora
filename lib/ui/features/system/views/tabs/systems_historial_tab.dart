import 'package:flutter/material.dart';
import '../../../../../data/models/report.dart';
import '../../../widgets/agora_incident_card.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../view_models/systems_dashboard_view_model.dart';
import '../../utils/system_utils.dart';

class SystemsHistorialTab extends StatelessWidget {
  final SystemsDashboardViewModel viewModel;

  const SystemsHistorialTab({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final items = viewModel.myResolvedIncidents;

    if (items.isEmpty) {
      return const CustomEmptyState(
          message: 'Aún no has resuelto incidencias.',
          icon: Icons.history_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final report = items[index];

        return AgoraIncidentCard(
          report: report,
          headerIconColor: Colors.green.shade600,
          actions: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Esta incidencia ha sido completada y cerrada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }
}