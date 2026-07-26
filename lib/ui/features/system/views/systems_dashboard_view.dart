import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../widgets/shared_chats_tab.dart';
import '../view_models/systems_dashboard_view_model.dart';
import 'incident_resolution_form.dart';
import '../../common/views/chat_room_view.dart';
import '../../widgets/custom_empty_state.dart';
import 'tabs/systems_account_tab.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/agora_incident_card.dart';
import 'tabs/systems_disponibles_tab.dart';
import 'tabs/systems_en_curso_tab.dart';
import 'tabs/systems_historial_tab.dart';

class SystemsDashboardView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const SystemsDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<SystemsDashboardView> createState() => _SystemsDashboardViewState();
}

class _SystemsDashboardViewState extends State<SystemsDashboardView> {
  int _selectedIndex = 0;
  final _viewModel = SystemsDashboardViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadDashboardData(widget.user);
      _viewModel.loadChats(); // <-- Agregar
      _viewModel.startPolling(); // <-- Agregar
    });
  }

  @override
  void dispose() {
    _viewModel.stopPolling(); // <-- Agregar
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Ágora - ${widget.user.role.displayName}',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
                onPressed: () {
                  _viewModel.loadDashboardData(widget.user);
                  _viewModel.loadChats();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // 2. Consumimos el cuerpo de la pestaña actual de forma limpia
          body: _buildCurrentTab(),
          
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEFEBE7),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? const Color(0xFF1C140E) : AppTheme.backgroundColor,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF8F7A6E),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inbox_outlined), 
                  activeIcon: Icon(Icons.inbox_rounded), 
                  label: 'Disponibles'
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.build_circle_outlined), 
                  activeIcon: Icon(Icons.build_circle_rounded), 
                  label: 'En Curso'
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      // 3. Este contador ahora sí se actualizará en tiempo real
                      if (_viewModel.totalUnreadChatMessages > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red, 
                              shape: BoxShape.circle
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16, 
                              minHeight: 16
                            ),
                            child: Text(
                              '${_viewModel.totalUnreadChatMessages}',
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 9, 
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.chat_bubble_rounded),
                  label: 'Chats',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined), 
                  activeIcon: Icon(Icons.history_rounded), 
                  label: 'Historial'
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded), 
                  activeIcon: Icon(Icons.person_rounded), 
                  label: 'Cuenta'
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    if (_viewModel.isLoading &&
        _viewModel.availableReports.isEmpty &&
        _viewModel.myInProgressIncidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return SystemsDisponiblesTab(
          viewModel: _viewModel,
          user: widget.user,
          onTabChange: _onItemTapped,
        );
      case 1:
        return SystemsEnCursoTab(
          viewModel: _viewModel,
          user: widget.user,
        );
      case 2:
        return SharedChatsTab( 
          viewModel: _viewModel,
          currentUser: widget.user,
          title: 'Chats Activos',
        );
      case 3:
        return SystemsHistorialTab(
          viewModel: _viewModel,
        );
      case 4:
      default:
        return SystemsAccountTab(
          user: widget.user,
          viewModel: _viewModel,
          onLogout: widget.onLogout,
        );
    }
  }
}