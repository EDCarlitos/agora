import 'package:flutter/material.dart';
import '../../../../../data/models/report.dart';
import '../../../../core/theme.dart';
import '../../../widgets/report_card.dart';
import '../../view_models/student_dashboard_view_model.dart';

class StudentIncidentsTab extends StatelessWidget {
  final StudentDashboardViewModel viewModel;
  final Function(Report) onShowDetail;
  final VoidCallback onSeeAllChats;

  const StudentIncidentsTab({
    super.key,
    required this.viewModel,
    required this.onShowDetail,
    required this.onSeeAllChats,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final localReportDate = dateTime.toLocal();
    final difference = now.difference(localReportDate);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hace 1 día';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final allIncidents = viewModel.incidents.toList();
    final now = DateTime.now();

    final recentIncidents = allIncidents.where((r) {
      final localDate = r.dateTime.toLocal();
      final difference = now.difference(localDate);
      return difference.inHours <= 24;
    }).take(5).toList(); 

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
                      TextButton(
                        onPressed: onSeeAllChats,
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(color: Color(0xFFFBBF24), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: recentIncidents.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay reportes en las últimas 24h',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recentIncidents.length,
                          itemBuilder: (context, index) {
                            final item = recentIncidents[index];
                            return _buildRecentCard(item);
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
                _buildSectionHeader('Incidencias de Sistemas'),
                const SizedBox(height: 8),
                if (allIncidents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No hay reportes activos.'),
                  )
                else
                  ...allIncidents.map((r) => ReportCard(
                        report: r,
                        icon: Icons.computer_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                        trailingText: _getTimeAgo(r.dateTime),
                        onTap: () => onShowDetail(r),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
        Text(
          'Ver todos',
          style: TextStyle(
            color: AppTheme.primaryColor.withValues(alpha: 0.8), 
            fontSize: 12, 
            fontWeight: FontWeight.bold
          ),
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
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: report.imageUrl == null
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                            const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          ],
                        )
                      : null,
                  image: report.imageUrl != null
                      ? DecorationImage(image: NetworkImage(report.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: report.imageUrl == null
                    ? Center(
                        child: Icon(Icons.settings_input_hdmi_rounded, color: Colors.blue.shade200, size: 32),
                      )
                    : null,
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