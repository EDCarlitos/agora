import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/custom_empty_state.dart';

class MockIncidencia {
  final String id;
  final String reporteId;
  final String titulo;
  final String edificio;
  final String aula;
  final String asignadoA;
  final String estado; // 'EN_PROCESO', 'FINALIZADA', 'REABIERTA'
  final DateTime fechaCreacion;
  final String descripcionResolucion;

  const MockIncidencia({
    required this.id,
    required this.reporteId,
    required this.titulo,
    required this.edificio,
    required this.aula,
    required this.asignadoA,
    required this.estado,
    required this.fechaCreacion,
    required this.descripcionResolucion,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(fechaCreacion);
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    return 'Hace ${difference.inDays} días';
  }
}

class AdminIncidenciasDashboardView extends StatefulWidget {
  const AdminIncidenciasDashboardView({super.key});

  @override
  State<AdminIncidenciasDashboardView> createState() => _AdminIncidenciasDashboardViewState();
}

class _AdminIncidenciasDashboardViewState extends State<AdminIncidenciasDashboardView> {
  String _searchQuery = '';
  String? _selectedStatusFilter;
  int _currentPage = 1;
  static const int _itemsPerPage = 4;

  final List<MockIncidencia> _mockIncidencias = [
    MockIncidencia(
      id: '201',
      reporteId: '102',
      titulo: 'Reparación compresor aire acondicionado',
      edificio: 'Edificio A',
      aula: 'Aula A-204',
      asignadoA: 'Roberto Mantenimiento',
      estado: 'EN_PROCESO',
      fechaCreacion: DateTime.now().subtract(const Duration(hours: 1)),
      descripcionResolucion: 'En revisión técnica del módulo de condensador y recarga de refrigerante.',
    ),
    MockIncidencia(
      id: '202',
      reporteId: '104',
      titulo: 'Restablecimiento de cableado ethernet puerto 12',
      edificio: 'Edificio de Cómputo',
      aula: 'Server Room B',
      asignadoA: 'Sofia Sistemas',
      estado: 'FINALIZADA',
      fechaCreacion: DateTime.now().subtract(const Duration(hours: 5)),
      descripcionResolucion: 'Reemplazo de patch cord Cat6 y prueba de enlace a 1Gbps exitosa.',
    ),
    MockIncidencia(
      id: '203',
      reporteId: '107',
      titulo: 'Revisión por falla intermitente en switch de red',
      edificio: 'Biblioteca',
      aula: 'Sala de Redes 1',
      asignadoA: 'Sofia Sistemas',
      estado: 'REABIERTA',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
      descripcionResolucion: 'Solicitud de reapertura por inconsistencia de conectividad registrada.',
    ),
  ];

  void _showIncidenciaDetailModal(MockIncidencia incidencia) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.build_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ficha Técnica #${incidencia.id}',
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
                incidencia.titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _DetailField(icon: Icons.confirmation_number_outlined, label: 'Reporte Origen', value: '#${incidencia.reporteId}'),
              const SizedBox(height: 8),
              _DetailField(icon: Icons.location_on_outlined, label: 'Ubicación', value: '${incidencia.edificio} - ${incidencia.aula}'),
              const SizedBox(height: 8),
              _DetailField(icon: Icons.engineering_outlined, label: 'Personal Asignado', value: incidencia.asignadoA),
              const SizedBox(height: 8),
              _DetailField(icon: Icons.access_time, label: 'Fecha de Alta', value: incidencia.timeAgo),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  _buildStatusBadge(incidencia.estado, isDark),
                ],
              ),
              const Divider(height: 24),
              const Text('Notas de Resolución Técnica:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  incidencia.descripcionResolucion,
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

    final filtered = _mockIncidencias.where((inc) {
      final matchesQuery = inc.id.contains(_searchQuery) ||
          inc.reporteId.contains(_searchQuery) ||
          inc.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.asignadoA.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inc.edificio.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == null || inc.estado == _selectedStatusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    final totalPages = (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
    final safePage = _currentPage.clamp(1, totalPages);

    final startIndex = (safePage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    final paginatedList = filtered.sublist(startIndex, endIndex);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header antidesbordamiento de píxeles
            _buildHeaderBanner(theme, isDark, filtered.length),

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
                    hintText: 'Buscar por ID, encargado o aula...',
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
                    label: const Text('Todas'),
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
                  ChoiceChip(
                    label: const Text('En Proceso'),
                    selected: _selectedStatusFilter == 'EN_PROCESO',
                    onSelected: (_) {
                      setState(() {
                        _selectedStatusFilter = _selectedStatusFilter == 'EN_PROCESO' ? null : 'EN_PROCESO';
                        _currentPage = 1;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Finalizadas'),
                    selected: _selectedStatusFilter == 'FINALIZADA',
                    onSelected: (_) {
                      setState(() {
                        _selectedStatusFilter = _selectedStatusFilter == 'FINALIZADA' ? null : 'FINALIZADA';
                        _currentPage = 1;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Reabiertas'),
                    selected: _selectedStatusFilter == 'REABIERTA',
                    onSelected: (_) {
                      setState(() {
                        _selectedStatusFilter = _selectedStatusFilter == 'REABIERTA' ? null : 'REABIERTA';
                        _currentPage = 1;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista Minimalista de Tarjetas Responsivas (CERO Scroll Horizontal)
            Expanded(
              child: filtered.isEmpty
                  ? const CustomEmptyState(
                      icon: Icons.engineering_outlined,
                      message: 'No se encontraron incidencias con los criterios seleccionados.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: paginatedList.length,
                      itemBuilder: (context, index) {
                        final inc = paginatedList[index];
                        return _buildMinimalistIncidenciaCard(inc, isDark);
                      },
                    ),
            ),

            // Barra de Paginación Fija al Pie
            _buildPaginationBar(safePage, totalPages, filtered.length, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistIncidenciaCard(MockIncidencia inc, bool isDark) {
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
        onTap: () => _showIncidenciaDetailModal(inc),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Incidencia #${inc.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Reporte #${inc.reporteId})',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                      ),
                    ],
                  ),
                  _buildStatusBadge(inc.estado, isDark),
                ],
              ),
              const SizedBox(height: 8),

              // Linea 2: Título Principal
              Text(
                inc.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Linea 3: Encargado + Ubicación + Tiempo
              Row(
                children: [
                  Icon(Icons.engineering_outlined, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Técnico: ${inc.asignadoA} • ${inc.edificio} - ${inc.aula}',
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
                    inc.timeAgo,
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
                  'Consulta de Incidencias Técnicas',
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
            'Vista minimalista sin scroll horizontal. Toca una incidencia para consultar sus notas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String estado, bool isDark) {
    Color bg;
    Color fg;
    String textLabel;

    switch (estado) {
      case 'EN_PROCESO':
        bg = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFE8F0FF);
        fg = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
        textLabel = 'En Proceso';
        break;
      case 'FINALIZADA':
        bg = isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F8EE);
        fg = isDark ? Colors.greenAccent : const Color(0xFF16A34A);
        textLabel = 'Finalizada';
        break;
      case 'REABIERTA':
        bg = isDark ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF);
        fg = isDark ? Colors.purpleAccent : const Color(0xFF9333EA);
        textLabel = 'Reabierta';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        textLabel = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        textLabel,
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
