import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../../data/models/report.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../widgets/agora_incident_card.dart';
import '../../view_models/systems_dashboard_view_model.dart';
import '../../utils/system_utils.dart';
import '../../../common/views/chat_room_view.dart';
import '../incident_resolution_form.dart';

class SystemsEnCursoTab extends StatelessWidget {
  final SystemsDashboardViewModel viewModel;
  final User user;

  const SystemsEnCursoTab({
    super.key,
    required this.viewModel,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final items = viewModel.myInProgressIncidents;

    if (items.isEmpty) {
      return const CustomEmptyState(
          message: 'No tienes incidencias en curso.',
          icon: Icons.build_circle_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final report = items[index];

        return AgoraIncidentCard(
          report: report,
          headerIconColor: Colors.blue.shade600,
          actions: [
            Row(
              children: [
                Expanded(
                  child: AgoraSecondaryButton(
                    text: 'Abrir Chat',
                    icon: Icons.forum_outlined,
                    color: Colors.blue.shade600,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomView(report: report, currentUser: user),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AgoraPrimaryButton(
                    text: 'Finalizar',
                    icon: Icons.check_circle_outline,
                    backgroundColor: Colors.green.shade600,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          final incId = int.tryParse(report.incidenciaId ?? report.id) ?? 0;
                          return IncidentResolutionForm(
                            incidenciaId: incId,
                            onSubmit: (descripcion, imagePaths) async {
                              final success = await viewModel.resolveIncident(incId, descripcion, imagePaths, user);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incidencia finalizada correctamente.'), backgroundColor: Colors.green),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}