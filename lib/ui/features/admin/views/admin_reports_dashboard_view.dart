import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/custom_empty_state.dart';

class AdminReportsDashboardView extends StatefulWidget {
  const AdminReportsDashboardView({super.key});

  @override
  State<AdminReportsDashboardView> createState() => _AdminReportsDashboardViewState();
}

class _AdminReportsDashboardViewState extends State<AdminReportsDashboardView> {
  String _searchQuery = '';
  ReportStatus? _selectedStatusFilter;
  int _currentPage = 1;
  static const int _itemsPerPage = 4;

  final List<Report> _mockReports = [
    Report(
      id: '101',
      title: 'Proyector sin señal y parpadeo intermitente HDMI',
      building: 'Edificio de Cómputo',
      classroom: 'Lab Cómputo 3',
      dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
      details: 'El proyector no reconoce el cable HDMI y presenta pantalla azul intermitente durante las clases.',
      status: ReportStatus.pendiente,
      reportedBy: 'carlos_estudiante',
    ),
    Report(
      id: '102',
      title: 'Aire acondicionado haciendo ruido fuerte',
      building: 'Edificio A',
      classroom: 'Aula A-204',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      details: 'La unidad exterior emite vibraciones excesivas y no enfria adecuadamente el aula.',
      status: ReportStatus.enProceso,
      reportedBy: 'maria_rodriguez',
    ),
    Report(
      id: '103',
      title: 'Falta de suministros de limpieza e higiene',
      building: 'Sala General',
      classroom: 'Baños Planta Baja',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      details: 'Se requiere reposición inmediata de jabón líquido y papel sanitario en sanitarios.',
      status: ReportStatus.resuelto,
      reportedBy: 'juan_perez',
    ),
    Report(
      id: '104',
      title: 'Cable de red dañado en rack principal',
      building: 'Edificio de Cómputo',
      classroom: 'Server Room B',
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      details: 'El conector RJ45 del puerto 12 se encuentra roto interrumpiendo el enlace.',
      status: ReportStatus.resuelto,
      reportedBy: 'sofia_sistemas',
    ),
    Report(
      id: '105',
      title: 'Reporte de prueba sin datos de evidencia',
      building: 'Edificio B',
      classroom: 'Aula B-101',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      details: 'Reporte rechazado por falta de descripción técnica y evidencia fotográfica.',
      status: ReportStatus.rechazado,
      reportedBy: 'pedro_gomez',
    ),
  ];

  void _showReportDetailModal(Report report) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Detalle de Reporte #${report.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _DetailField(icon: Icons.location_on_outlined, label: 'Ubicación', value: '${report.building} - ${report.classroom}'),
              const SizedBox(height: 8),
              _DetailField(icon: Icons.person_outline, label: 'Reportado por', value: report.reportedBy),
              const SizedBox(height: 8),
              _DetailField(icon: Icons.access_time, label: 'Fecha de Registro', value: report.timeAgo),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  const Text('Estado Actual: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  _buildStatusBadge(report.status, isDark),
                ],
              ),
              const Divider(height: 24),
              const Text('Descripción detallada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.details,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          AgoraPrimaryButton(
            text: 'Cerrar',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredReports = _mockReports.where((r) {
      final matchesQuery = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.building.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.classroom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reportedBy.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.contains(_searchQuery);
      final matchesStatus = _selectedStatusFilter == null || r.status == _selectedStatusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    final totalPages = (filteredReports.length / _itemsPerPage).ceil().clamp(1, 999);
    final safePage = _currentPage.clamp(1, totalPages);

    final startIndex = (safePage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredReports.length);
    final paginatedReports = filteredReports.sublist(startIndex, endIndex);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header antidesbordamiento de píxeles
            _buildHeaderBanner(theme, isDark, filteredReports.length),

            // Buscador por Texto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.secondaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por título, aula o usuario...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Chips de Estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatusFilter = null;
                        _currentPage = 1;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  ...ReportStatus.values.map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatusFilter = isSelected ? null : status;
                            _currentPage = 1;
                          });
                        },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista Minimalista de Tarjetas Responsivas (CERO Scroll Horizontal)
            Expanded(
              child: filteredReports.isEmpty
                  ? const CustomEmptyState(
                      icon: Icons.assignment_late_outlined,
                      message: 'No se encontraron reportes con los filtros seleccionados.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: paginatedReports.length,
                      itemBuilder: (context, index) {
                        final report = paginatedReports[index];
                        return _buildMinimalistReportCard(report, isDark);
                      },
                    ),
            ),

            // Barra de Paginación Fija al Pie
            _buildPaginationBar(safePage, totalPages, filteredReports.length, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistReportCard(Report report, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.secondaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: () => _showReportDetailModal(report),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linea 1: ID Badge + Estado Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Reporte #${report.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  _buildStatusBadge(report.status, isDark),
                ],
              ),
              const SizedBox(height: 8),

              // Linea 2: Título Principal
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Linea 3: Ubicación + Usuario + Tiempo
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondaryColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${report.building} • ${report.classroom}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    report.timeAgo,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar(int currentPage, int totalPages, int totalItems, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.secondaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: const Text('Anterior', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Text(
            'Página $currentPage de $totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          OutlinedButton.icon(
            onPressed: currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('Siguiente', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(ThemeData theme, bool isDark, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.secondaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Consulta de Reportes Institucionales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCount Registros',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vista minimalista sin scroll horizontal. Toca un reporte para consultar su detalle.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status, bool isDark) {
    Color bg;
    Color fg;

    switch (status) {
      case ReportStatus.pendiente:
        bg = isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFF3E0);
        fg = isDark ? Colors.amberAccent : const Color(0xFFD97706);
        break;
      case ReportStatus.enProceso:
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        break;
      case ReportStatus.resuelto:
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        break;
      case ReportStatus.rechazado:
        bg = isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFFE8E8);
        fg = isDark ? Colors.redAccent : const Color(0xFFDC2626);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
