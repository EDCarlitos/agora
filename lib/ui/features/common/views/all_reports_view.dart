import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../../widgets/agora_incident_card.dart';
import '../../widgets/custom_empty_state.dart';
import '../../students/views/report_detail_view.dart';

class AllReportsView extends StatefulWidget {
  final String title;
  final List<Report> reports;
  final User currentUser;
  final Future<void> Function()? onRefresh;

  const AllReportsView({
    super.key,
    required this.title,
    required this.reports,
    required this.currentUser,
    this.onRefresh,
  });

  @override
  State<AllReportsView> createState() => _AllReportsViewState();
}

class _AllReportsViewState extends State<AllReportsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ReportStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Report> get _filteredReports {
    return widget.reports.where((report) {
      final matchesSearch = _searchQuery.isEmpty ||
          report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.classroom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.building.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.reportedBy.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == null || report.status == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvasBg = theme.scaffoldBackgroundColor;
    final filtered = _filteredReports;

    return Scaffold(
      backgroundColor: canvasBg,
      appBar: AppBar(
        backgroundColor: canvasBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
            fontSize: 19,
            color: AppTheme.secondaryColor,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        color: AppTheme.primaryColor,
        child: Column(
          children: [
            // Barra de Búsqueda y Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título, aula, edificio o persona...',
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Chips de Filtro por Estado
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', null, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('Pendiente', ReportStatus.pendiente, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('En Proceso', ReportStatus.enProceso, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('Resuelto', ReportStatus.resuelto, isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('Rechazado', ReportStatus.rechazado, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Contador resumen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mostrando ${filtered.length} de ${widget.reports.length} reportes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista Principal
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: CustomEmptyState(
                          message: _searchQuery.isNotEmpty || _selectedStatusFilter != null
                              ? 'No se encontraron reportes con los filtros aplicados.'
                              : 'No hay reportes disponibles.',
                          icon: Icons.search_off_rounded,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        return AgoraIncidentCard(
                          report: report,
                          headerIconColor: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailView(
                                  report: report,
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ReportStatus? status, bool isDark) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : AppTheme.secondaryColor),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.1),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
    );
  }
}
