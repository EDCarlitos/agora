import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../normal_user/views/chat_room_view.dart';
import '../view_models/systems_dashboard_view_model.dart';
import 'incident_resolution_form.dart'; // Importaremos el formulario estricto

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
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper para mapear el JSON del backend al modelo Report de Frontend
  Report _parseToReport(Map<String, dynamic> json, {String? overrideId}) {
    final aula = json['aula'] ?? {};
    final edificio = aula['edificio'] ?? {};
    final reportante = json['reportante'] ?? {};
    final imagenes = json['imagenes'] as List? ?? [];

    ReportStatus parsedStatus = ReportStatus.pendiente;
    if (json['estado'] == 'ACEPTADO') parsedStatus = ReportStatus.enProceso;
    if (json['estado'] == 'FINALIZADO' || json['estado'] == 'RECHAZADO') parsedStatus = ReportStatus.resuelto;

    return Report(
      id: overrideId ?? json['id'].toString(),
      title: json['titulo'] ?? 'Sin título',
      classroom: aula['nombre'] ?? 'Sin aula',
      building: edificio['nombre'] ?? 'Sin edificio',
      dateTime: json['fechaCreacion'] != null ? DateTime.parse(json['fechaCreacion']).toLocal() : DateTime.now(),
      details: json['descripcion'] ?? '',
      status: parsedStatus,
      reportedBy: reportante['username'] ?? reportante['email'] ?? 'Usuario',
      imageUrl: imagenes.isNotEmpty ? imagenes[0]['url'] : null,
      area: ReportArea.sistema,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            onPressed: () => _viewModel.loadDashboardData(widget.user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.availableReports.isEmpty && _viewModel.myInProgressIncidents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          switch (_selectedIndex) {
            case 0:
              return _buildDisponiblesTab();
            case 1:
              return _buildEnCursoTab();
            case 2:
              return _buildHistorialTab();
            case 3:
            default:
              return _buildCuentaTab();
          }
        },
      ),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox_rounded),
              label: 'Disponibles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_circle_outlined),
              activeIcon: Icon(Icons.build_circle_rounded),
              label: 'En Curso',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cuenta',
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TABS DE SISTEMAS
  // ===========================================================================

  Widget _buildDisponiblesTab() {
    final items = _viewModel.availableReports;
    if (items.isEmpty) {
      return _buildEmptyState('No hay reportes nuevos por asignar.', Icons.inbox_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final jsonReport = items[index];
        final report = _parseToReport(jsonReport);

        return _buildIncidentCard(
          report: report,
          isDark: Theme.of(context).brightness == Brightness.dark,
          headerColor: AppTheme.primaryColor,
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final success = await _viewModel.assignReportToMe(jsonReport['id'], widget.user);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incidencia asignada a ti.'), backgroundColor: Colors.green),
                  );
                  setState(() => _selectedIndex = 1); // Mandarlo a "En Curso"
                }
              },
              icon: const Icon(Icons.assignment_ind_rounded, size: 18),
              label: const Text('Asignarme esta incidencia'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildEnCursoTab() {
    final items = _viewModel.myInProgressIncidents;
    if (items.isEmpty) {
      return _buildEmptyState('No tienes incidencias en curso.', Icons.build_circle_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final jsonReport = items[index];
        final incidencia = jsonReport['incidencia'];
        
        // CUIDADO: Pasamos el ID de la incidencia para que el ChatRoom funcione
        final report = _parseToReport(jsonReport, overrideId: incidencia['id'].toString())
            .copyWith(status: ReportStatus.enProceso);

        return _buildIncidentCard(
          report: report,
          isDark: Theme.of(context).brightness == Brightness.dark,
          headerColor: Colors.blue.shade600,
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomView(report: report, currentUser: widget.user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('Abrir Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      side: BorderSide(color: Colors.blue.shade600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => IncidentResolutionForm(
                          incidenciaId: incidencia['id'],
                          onSubmit: (descripcion, imagePaths) async {
                            final success = await _viewModel.resolveIncident(incidencia['id'], descripcion, imagePaths, widget.user);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Incidencia finalizada correctamente.'), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildHistorialTab() {
    final items = _viewModel.myResolvedIncidents;
    if (items.isEmpty) {
      return _buildEmptyState('Aún no has resuelto incidencias.', Icons.history_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final jsonReport = items[index];
        final report = _parseToReport(jsonReport).copyWith(status: ReportStatus.resuelto);

        return _buildIncidentCard(
          report: report,
          isDark: Theme.of(context).brightness == Brightness.dark,
          headerColor: Colors.green.shade600,
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

  // ===========================================================================
  // WIDGETS REUTILIZABLES
  // ===========================================================================

  Widget _buildIncidentCard({required Report report, required bool isDark, required Color headerColor, required List<Widget> actions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFEBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del reporte (si existe)
          if (report.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                report.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: headerColor.withOpacity(0.15),
                      child: Icon(Icons.computer_rounded, color: headerColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reportado por: ${report.reportedBy}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${report.classroom} - ${report.building}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...actions,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCuentaTab() {
    // ... Mismo código de la pestaña cuenta de la respuesta anterior
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    child: const Icon(Icons.engineering_rounded, size: 30, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                        ),
                        Text(
                          widget.user.email,
                          style: TextStyle(fontSize: 13, color: theme.hintColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.user.role.displayName.toUpperCase(),
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
          const Text(
            'Estadísticas de Servicio',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('En Curso', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          '${_viewModel.myInProgressIncidents.length}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Resueltas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          '${_viewModel.myResolvedIncidents.length}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}