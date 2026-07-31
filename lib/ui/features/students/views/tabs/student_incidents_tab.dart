import 'package:flutter/material.dart';
import '../../../../../data/models/report.dart';
import '../../../../../data/models/user.dart';
import '../../../../core/theme.dart';
import '../../../widgets/agora_incident_card.dart';
import '../../view_models/student_dashboard_view_model.dart';
import '../../../widgets/custom_empty_state.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/agora_network_image.dart';
import '../../../common/views/all_reports_view.dart';

class StudentIncidentsTab extends StatelessWidget {
  final StudentDashboardViewModel viewModel;
  final User currentUser;
  final Function(Report) onShowDetail;
  final VoidCallback onSeeAllChats;

  const StudentIncidentsTab({
    super.key,
    required this.viewModel,
    required this.currentUser,
    required this.onShowDetail,
    required this.onSeeAllChats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Delegamos toda la responsabilidad de los datos al ViewModel
    final allIncidents = viewModel.incidents;
    final recentIncidents = viewModel.recentIncidents;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.offBlack : AppTheme.secondaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reportes Recientes',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AgoraTextButton(
                        text: 'Ver todos',
                        color: const Color(0xFFFBBF24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllReportsView(
                                title: 'Reportes Recientes',
                                reports: recentIncidents,
                                currentUser: currentUser,
                                onRefresh: () => viewModel.loadReports(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: recentIncidents.isEmpty
                      ? const CustomEmptyState(message: 'No hay reportes en las últimas 24h', icon: Icons.history_rounded)
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recentIncidents.length,
                          itemBuilder: (context, index) {
                            return _buildRecentCard(recentIncidents[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  'Incidencias de Sistemas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllReportsView(
                          title: 'Incidencias de Sistemas',
                          reports: allIncidents,
                          currentUser: currentUser,
                          onRefresh: () => viewModel.loadReports(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (allIncidents.isEmpty)
                  const CustomEmptyState(message: 'No hay reportes activos.', icon: Icons.assignment_outlined)
                else
                  ...allIncidents.map((r) => AgoraIncidentCard(
                        report: r,
                        headerIconColor: const Color(0xFF3B82F6),
                        onTap: () => onShowDetail(r),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        AgoraTextButton(
          text: 'Ver todos',
          color: AppTheme.primaryColor.withValues(alpha: 0.8),
          onPressed: onTap ?? () {},
        ),
      ],
    );
  }

  Widget _buildRecentCard(Report report) {
    return GestureDetector(
      onTap: () => onShowDetail(report),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: report.imageUrl == null
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E3A8A).withOpacity(0.5),
                              const Color(0xFF3B82F6).withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.settings_input_hdmi_rounded, color: Colors.blue.shade200, size: 32),
                        ),
                      )
                    : AgoraNetworkImage(
                        imageUrl: report.imageUrl!,
                        borderRadius: BorderRadius.circular(8),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white60, size: 12),
                const SizedBox(width: 4),
                Text(report.classroom, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}