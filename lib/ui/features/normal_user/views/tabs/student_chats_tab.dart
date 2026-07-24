import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../../data/models/report.dart';
import '../../../../core/theme.dart';
import '../../view_models/student_dashboard_view_model.dart';
import '../chat_room_view.dart';

class StudentChatsTab extends StatelessWidget {
  final StudentDashboardViewModel viewModel;
  final User currentUser;

  const StudentChatsTab({
    super.key,
    required this.viewModel,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final misChatsApi = viewModel.chats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Mensajes y Soporte',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D16) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8E2DA),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar chats...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 13.5,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tus Chats Activos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isDark ? Colors.white70 : AppTheme.secondaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: viewModel.isLoadingChats
                ? const Center(child: CircularProgressIndicator())
                : misChatsApi.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes chats de soporte aún.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white60 : AppTheme.secondaryColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: misChatsApi.length,
                        itemBuilder: (context, index) {
                          return _buildChatChannelItem(context, misChatsApi[index], isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatChannelItem(BuildContext context, dynamic chat, bool isDark) {
    final int incidenciaId = chat['id'];
    final String titulo = chat['titulo'] ?? 'Sin título';
    final String aula = chat['aula'] ?? 'Sin ubicación';
    final String adminAsignado = chat['usuarioAdministrativo'] ?? 'Personal asignado';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFEBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final mockReport = Report(
              id: incidenciaId.toString(),
              title: titulo,
              classroom: aula,
              building: '',
              dateTime: DateTime.now(),
              details: '',
              status: ReportStatus.enProceso,
              reportedBy: currentUser.name,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomView(
                  report: mockReport,
                  currentUser: currentUser,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.2,
                          color: isDark ? Colors.white : AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atendido por: $adminAsignado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EN CURSO',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}