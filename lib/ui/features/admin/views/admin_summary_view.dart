import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/report_service.dart';
import '../../../../data/services/weather_service.dart';
import '../../../../data/models/weather_data.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../widgets/admin_activity_tile.dart';
import '../widgets/admin_summary_kpi_card.dart';

class AdminSummaryView extends StatefulWidget {
  final User user;
  final VoidCallback onNavigateToUsers;

  const AdminSummaryView({
    super.key,
    required this.user,
    required this.onNavigateToUsers,
  });

  @override
  State<AdminSummaryView> createState() => _AdminSummaryViewState();
}

class _AdminSummaryViewState extends State<AdminSummaryView> {
  Future<Map<String, dynamic>>? _statsFuture;
  late Future<WeatherData> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService().getCurrentWeather();
    _loadStats();
  }

  void _loadStats() {
    final token = AuthService().token;
    setState(() {
      _weatherFuture = WeatherService().getCurrentWeather();
      if (token != null && token.isNotEmpty) {
        _statsFuture = ReportService().getSummaryStats(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Bienvenida
          _buildWelcomeBanner(context, isDark),
          const SizedBox(height: 24),

          // Título de Métricas KPI con botón de refrescar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Métricas de Incidencias',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Actualizar métricas',
                onPressed: _loadStats,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Carga de datos reales mediante FutureBuilder
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error al cargar métricas: ${snapshot.error}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadStats,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final stats = snapshot.data ?? {};
              final totalReportes = stats['totalReportes'] ?? 0;
              final aceptados = stats['aceptados'] ?? 0;
              final nuevos = stats['nuevos'] ?? 0;
              final rechazados = stats['rechazados'] ?? 0;
              final recentActivity = (stats['recentActivity'] as List<dynamic>?) ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid de Tarjetas KPI Responsivas con datos reales
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.45,
                        children: [
                          AdminSummaryKpiCard(
                            title: 'Total Reportes',
                            value: '$totalReportes',
                            icon: Icons.assignment_outlined,
                            color: AppTheme.primaryColor,
                            isDark: isDark,
                          ),
                          AdminSummaryKpiCard(
                            title: 'Aceptados',
                            value: '$aceptados',
                            icon: Icons.check_circle_outline,
                            color: AppTheme.successColor,
                            isDark: isDark,
                          ),
                          AdminSummaryKpiCard(
                            title: 'Nuevos / Pendientes',
                            value: '$nuevos',
                            icon: Icons.hourglass_bottom_outlined,
                            color: AppTheme.infoColor,
                            isDark: isDark,
                          ),
                          AdminSummaryKpiCard(
                            title: 'Rechazados',
                            value: '$rechazados',
                            icon: Icons.cancel_outlined,
                            color: AppTheme.errorColor,
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Distribución Visual Real de Estados
                  _buildDistributionCard(theme, isDark, totalReportes, aceptados, nuevos, rechazados),
                  const SizedBox(height: 24),

                  // Actividad Reciente del Sistema (Real de la BD)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Actividad Reciente del Sistema',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AgoraTextButton(
                        text: 'Ir a Usuarios',
                        onPressed: widget.onNavigateToUsers,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista de Actividad Reciente Real
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppTheme.secondaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: recentActivity.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text('No hay actividad reciente registrada.'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentActivity.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = recentActivity[index];
                              final estado = (item['estado'] ?? '').toString().toUpperCase();

                              IconData icon = Icons.assignment;
                              Color iconColor = AppTheme.infoColor;

                              if (estado == 'ACEPTADO' || estado == 'FINALIZADA') {
                                icon = Icons.check_circle;
                                iconColor = AppTheme.successColor;
                              } else if (estado == 'RECHAZADO') {
                                icon = Icons.cancel;
                                iconColor = AppTheme.errorColor;
                              } else if (estado == 'NUEVO') {
                                icon = Icons.fiber_new;
                                iconColor = AppTheme.primaryColor;
                              }

                              return AdminActivityTile(
                                icon: icon,
                                iconColor: iconColor,
                                title: 'Reporte #${item['id']} - ${item['titulo']}',
                                subtitle: '${item['ubicacion']} • Por ${item['reportante']}',
                                time: _formatRelativeTime(item['fechaCreacion']),
                                isDark: isDark,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF4A0E1A), AppTheme.primaryColor]
              : [AppTheme.primaryColor, const Color(0xFFB51A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Panel de Administración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrentDate(),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¡Bienvenido, ${widget.user.name}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Resumen general del estado del sistema, métricas de reportes e incidencias institucionales.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FutureBuilder<WeatherData>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              final weather = snapshot.data ??
                  WeatherData(
                    temperature: 31.0,
                    windSpeed: 12.5,
                    weatherCode: 0,
                    isDay: true,
                    location: 'Cancún (UPQROO)',
                  );

              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(weather.conditionIcon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${weather.temperature.round()}°C — ${weather.conditionText}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              weather.location,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.air, color: Colors.white70, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${weather.windSpeed} km/h',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text(
              'Descargar PDF de Auditoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showMonthYearDialog(context),
          ),
        ],
      ),
    );
  }

  void _showMonthYearDialog(BuildContext context) {
    final theme = Theme.of(context);
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auditoría Mensual PDF',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecciona el periodo para generar el reporte:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(months[index]),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedMonth = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [2024, 2025, 2026, 2027].map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text('$y'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedYear = val);
                    },
                  ),
                ],
              ),
              actionsOverflowButtonSpacing: 8,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Generar PDF'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _handleDownloadPdf(context, selectedMonth, selectedYear);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDownloadPdf(BuildContext context, int month, int year) async {
    final token = AuthService().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión activa para descargar el PDF.')),
      );
      return;
    }

    bool dialogShown = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        dialogShown = true;
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando reporte PDF...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      debugPrint('Solicitando PDF de auditoría a la API ($month/$year)...');
      final pdfBytes = await ReportService().downloadAuditPdf(token, month: month, year: year);
      debugPrint('PDF recibido exitosamente: ${pdfBytes.length} bytes.');

      final outputDir = await getTemporaryDirectory();
      final filePath = '${outputDir.path}/auditoria_${month}_$year.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      debugPrint('PDF guardado en disco: $filePath');

      if (context.mounted && dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generado correctamente (${pdfBytes.length} bytes).'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }

      // Lanzar visualizador de PDF en segundo plano sin congelar la app
      OpenFilex.open(filePath).then((result) {
        debugPrint('OpenFilex resultado: ${result.type} - ${result.message}');
      }).catchError((err) {
        debugPrint('Error en OpenFilex: $err');
      });

    } catch (e) {
      debugPrint('Error al generar PDF: $e');
      if (context.mounted && dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Widget _buildDistributionCard(ThemeData theme, bool isDark, int total, int aceptados, int nuevos, int rechazados) {
    final denom = total > 0 ? total : 1;
    final pAceptados = total > 0 ? ((aceptados / denom) * 100).round() : 0;
    final pNuevos = total > 0 ? ((nuevos / denom) * 100).round() : 0;
    final pRechazados = total > 0 ? ((rechazados / denom) * 100).round() : 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.secondaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Reportes por Estado',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (aceptados > 0 || total == 0)
                      Expanded(flex: aceptados > 0 ? aceptados : 1, child: Container(color: AppTheme.successColor)),
                    if (nuevos > 0)
                      Expanded(flex: nuevos, child: Container(color: AppTheme.infoColor)),
                    if (rechazados > 0)
                      Expanded(flex: rechazados, child: Container(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 8,
              spacing: 12,
              children: [
                _LegendItem(color: AppTheme.successColor, label: '$pAceptados% Aceptados'),
                _LegendItem(color: AppTheme.infoColor, label: '$pNuevos% Nuevos'),
                _LegendItem(color: AppTheme.errorColor, label: '$pRechazados% Rechazados'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
