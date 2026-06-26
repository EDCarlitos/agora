import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../view_models/student_dashboard_view_model.dart';

class StudentDashboardView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const StudentDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  final _viewModel = StudentDashboardViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      widget.onLogout();
    }
  }

  void _openCreateReportDialog(ReportType initialType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateReportDialog(
        initialType: initialType,
        reportedBy: widget.user.name,
        onReportCreated: (title, description, location, type, category, phone) async {
          await _viewModel.addReport(
            title: title,
            description: description,
            location: location,
            type: type,
            category: category,
            contactPhone: phone,
            reportedBy: widget.user.name,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Ágora Estudiantes'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final reports = _viewModel.filteredReports;

          return RefreshIndicator(
            onRefresh: () async {
              // Just simulate loading fresh data
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
                // Welcome Header Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                              : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${widget.user.name}!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reporta incidencias técnicas o publica objetos que hayas perdido en el campus universitario.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openCreateReportDialog(ReportType.incidencia),
                                  icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
                                  label: const Text('Incidencia'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.blueAccent : Colors.white,
                                    foregroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openCreateReportDialog(ReportType.objetoPerdido),
                                  icon: const Icon(Icons.search_rounded, size: 18),
                                  label: const Text('Objeto Perdido'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.tealAccent.shade700 : theme.colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Filters Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Reportes y Publicaciones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Type Filters Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Todos los Tipos'),
                                selected: _viewModel.typeFilter == null,
                                onSelected: (selected) =>
                                    _viewModel.setTypeFilter(null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Incidencias'),
                                selected: _viewModel.typeFilter == ReportType.incidencia,
                                onSelected: (selected) => _viewModel.setTypeFilter(
                                    selected ? ReportType.incidencia : null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Objetos Perdidos'),
                                selected: _viewModel.typeFilter == ReportType.objetoPerdido,
                                onSelected: (selected) => _viewModel.setTypeFilter(
                                    selected ? ReportType.objetoPerdido : null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status Filters Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Todos los Estados'),
                                selected: _viewModel.statusFilter == null,
                                onSelected: (selected) =>
                                    _viewModel.setStatusFilter(null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Pendiente'),
                                selected: _viewModel.statusFilter == ReportStatus.pendiente,
                                onSelected: (selected) => _viewModel.setStatusFilter(
                                    selected ? ReportStatus.pendiente : null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('En Proceso'),
                                selected: _viewModel.statusFilter == ReportStatus.enProceso,
                                onSelected: (selected) => _viewModel.setStatusFilter(
                                    selected ? ReportStatus.enProceso : null),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Resuelto'),
                                selected: _viewModel.statusFilter == ReportStatus.resuelto,
                                onSelected: (selected) => _viewModel.setStatusFilter(
                                    selected ? ReportStatus.resuelto : null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Reports List/Grid
                if (_viewModel.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reports.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 72,
                              color: theme.hintColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron reportes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta cambiar los filtros o publica uno nuevo usando los botones de arriba.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 720 ? 2 : 1,
                        mainAxisExtent: 220,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final report = reports[index];
                          return ReportCard(report: report);
                        },
                        childCount: reports.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncident = report.type == ReportType.incidencia;

    // Helper to format date
    final dateStr = '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}';

    // Color helpers for status
    Color statusColor;
    Color statusBgColor;
    switch (report.status) {
      case ReportStatus.pendiente:
        statusColor = const Color(0xFFD97706); // Amber
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      case ReportStatus.enProceso:
        statusColor = const Color(0xFF2563EB); // Blue
        statusBgColor = const Color(0xFFDBEAFE);
        break;
      case ReportStatus.resuelto:
        statusColor = const Color(0xFF16A34A); // Green
        statusBgColor = const Color(0xFFDCFCE7);
        break;
    }

    if (theme.brightness == Brightness.dark) {
      statusBgColor = statusColor.withOpacity(0.2);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Metadata row (Type, category & date)
            Row(
              children: [
                Icon(
                  isIncident ? Icons.report_gmailerrorred_rounded : Icons.search_rounded,
                  size: 14,
                  color: isIncident ? Colors.blue : Colors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  report.type.displayName,
                  style: TextStyle(
                    color: isIncident ? Colors.blue : Colors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Description
            Expanded(
              child: Text(
                report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.light ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Footer (Location & optional Phone)
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (report.contactPhone != null && report.contactPhone!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report.contactPhone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateReportDialog extends StatefulWidget {
  final ReportType initialType;
  final String reportedBy;
  final Future<void> Function(
    String title,
    String description,
    String location,
    ReportType type,
    String category,
    String? contactPhone,
  ) onReportCreated;

  const CreateReportDialog({
    super.key,
    required this.initialType,
    required this.reportedBy,
    required this.onReportCreated,
  });

  @override
  State<CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<CreateReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late ReportType _type;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = 'General';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == ReportType.incidencia ? 'Infraestructura' : 'Artículos Personales';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await widget.onReportCreated(
          _titleController.text,
          _descriptionController.text,
          _locationController.text,
          _type,
          _category,
          _type == ReportType.objetoPerdido ? _phoneController.text : null,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear reporte: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == ReportType.incidencia
        ? ['Infraestructura', 'Tecnología', 'Limpieza', 'Seguridad', 'General']
        : ['Artículos Personales', 'Documentos', 'Electrónicos', 'Libros', 'General'];

    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          Icon(
            _type == ReportType.incidencia ? Icons.report_gmailerrorred_rounded : Icons.search_rounded,
            color: _type == ReportType.incidencia ? Colors.blue : Colors.teal,
          ),
          const SizedBox(width: 8),
          Text('Publicar ${_type.displayName}'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented type selector
              SegmentedButton<ReportType>(
                segments: const [
                  ButtonSegment<ReportType>(
                    value: ReportType.incidencia,
                    label: Text('Incidencia'),
                    icon: Icon(Icons.report_gmailerrorred_rounded),
                  ),
                  ButtonSegment<ReportType>(
                    value: ReportType.objetoPerdido,
                    label: Text('Objeto Perdido'),
                    icon: Icon(Icons.search_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<ReportType> selection) {
                  setState(() {
                    _type = selection.first;
                    _category = _type == ReportType.incidencia ? 'Infraestructura' : 'Artículos Personales';
                  });
                },
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _type == ReportType.incidencia ? 'Título de la Incidencia' : 'Objeto Perdido',
                  hintText: _type == ReportType.incidencia ? 'Ej: Gotera en laboratorio 3' : 'Ej: Mochila negra marca Jansport',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación / Aula',
                  hintText: 'Ej: Edificio C, Segundo Piso, Aula 302',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa la ubicación' : null,
              ),
              const SizedBox(height: 16),

              // Contact Phone (Conditional for Lost Object)
              if (_type == ReportType.objetoPerdido) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de Contacto (Opcional)',
                    hintText: 'Ej: 555-1234',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa una descripción' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Publicar'),
        ),
      ],
    );
  }
}
