import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../../data/models/report.dart';
import '../../../../core/theme.dart';
import '../../view_models/student_dashboard_view_model.dart';
import '../../../widgets/user_profile_header_card.dart';
import '../../../widgets/custom_buttons.dart';

class StudentAccountTab extends StatelessWidget {
  final StudentDashboardViewModel viewModel;
  final User currentUser;
  final VoidCallback onLogout;
  final Function(Report) onShowDetail;

  const StudentAccountTab({
    super.key,
    required this.viewModel,
    required this.currentUser,
    required this.onLogout,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myReports = viewModel.getMyReports(currentUser);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserProfileHeaderCard(user: currentUser),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Reportes Publicados (${myReports.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (myReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No has publicado ningún reporte aún.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myReports.length,
              itemBuilder: (context, index) {
                final report = myReports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      report.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('${report.building} - ${report.classroom}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.status == ReportStatus.resuelto
                            ? Colors.green.withValues(alpha: 0.1)
                            : report.status == ReportStatus.enProceso
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        report.status.displayName,
                        style: TextStyle(
                          color: report.status == ReportStatus.resuelto
                              ? Colors.green
                              : report.status == ReportStatus.enProceso
                                  ? Colors.blue
                                  : Colors.amber.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => onShowDetail(report),
                  ),
                );
              },
            ),
          const SizedBox(height: 48),
          AgoraPrimaryButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout_rounded,
            backgroundColor: Colors.red.shade700,
            onPressed: onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}