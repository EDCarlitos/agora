import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../../data/models/report.dart';
import '../../../../core/theme.dart';
import '../../view_models/student_dashboard_view_model.dart';

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
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: currentUser.photoUrl != null
                        ? NetworkImage(currentUser.photoUrl!)
                        : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentUser.email,
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentUser.role.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}