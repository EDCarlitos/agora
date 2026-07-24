import 'package:flutter/material.dart';

import '../../../../../data/models/user.dart';
import '../../../../core/theme.dart';
import '../../view_models/student_dashboard_view_model.dart';
import '../../../../../data/models/report.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20, bottom: 8),
          child: Text(
            'Tus Chats Activos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ),
        
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              final activeChats = viewModel.chats;

              if (activeChats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes chats de soporte activos aún.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: activeChats.length,
                padding: const EdgeInsets.only(bottom: 100),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 80, 
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final Map<String, dynamic> chat = activeChats[index];
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    onTap: () {
                      final reportToChat = Report(
                        id: chat['id'].toString(),
                        title: chat['titulo'] ?? 'Incidencia de Soporte',
                        classroom: chat['aula'] ?? 'Sin ubicación',
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
                            report: reportToChat, 
                            currentUser: currentUser,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      chat['titulo']?.toString() ?? 'Incidencia de Soporte',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Toca para abrir la conversación...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 20,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}