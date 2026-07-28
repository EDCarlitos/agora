import 'package:flutter/material.dart';
import '../../../../data/models/user.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_buttons.dart';
import '../widgets/admin_activity_tile.dart';
import '../widgets/admin_summary_kpi_card.dart';

class AdminSummaryView extends StatelessWidget {
  final User user;
  final VoidCallback onNavigateToUsers;

  const AdminSummaryView({
    super.key,
    required this.user,
    required this.onNavigateToUsers,
  });

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
          _buildWelcomeBanner(isDark),
          const SizedBox(height: 24),

          // Título de Métricas KPI
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
          const SizedBox(height: 12),

          // Grid de Tarjetas KPI Responsivas
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
                    value: '48',
                    icon: Icons.assignment_outlined,
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                  AdminSummaryKpiCard(
                    title: 'Finalizados',
                    value: '32',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.successColor,
                    isDark: isDark,
                  ),
                  AdminSummaryKpiCard(
                    title: 'En Proceso',
                    value: '11',
                    icon: Icons.hourglass_bottom_outlined,
                    color: AppTheme.infoColor,
                    isDark: isDark,
                  ),
                  AdminSummaryKpiCard(
                    title: 'Rechazados',
                    value: '5',
                    icon: Icons.cancel_outlined,
                    color: AppTheme.errorColor,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Distribución Visual de Estados
          _buildDistributionCard(theme, isDark),
          const SizedBox(height: 24),

          // Actividad Reciente del Sistema
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
                onPressed: onNavigateToUsers,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista de Actividad Reciente
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.secondaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AdminActivityTile(
                  icon: Icons.check_circle,
                  iconColor: AppTheme.successColor,
                  title: 'Incidencia #104 Finalizada',
                  subtitle: 'Sofia Sistemas resolvió problema en Edificio Cómputo.',
                  time: 'Hace 25 min',
                  isDark: isDark,
                ),
                const Divider(height: 1),
                AdminActivityTile(
                  icon: Icons.cancel,
                  iconColor: AppTheme.errorColor,
                  title: 'Reporte #108 Rechazado',
                  subtitle: 'Reporte rechazado por falta de evidencia gráfica clara.',
                  time: 'Hace 1 hora',
                  isDark: isDark,
                ),
                const Divider(height: 1),
                AdminActivityTile(
                  icon: Icons.person_add,
                  iconColor: AppTheme.primaryColor,
                  title: 'Nuevo Usuario Registrado',
                  subtitle: 'Se dio de alta al usuario carlos_estudiante.',
                  time: 'Hace 3 horas',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark) {
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
            '¡Bienvenido, ${user.name}!',
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
        ],
      ),
    );
  }

  Widget _buildDistributionCard(ThemeData theme, bool isDark) {
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
                    Expanded(flex: 32, child: Container(color: AppTheme.successColor)),
                    Expanded(flex: 11, child: Container(color: AppTheme.infoColor)),
                    Expanded(flex: 5, child: Container(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.spaceAround,
              runSpacing: 8,
              spacing: 12,
              children: [
                _LegendItem(color: AppTheme.successColor, label: '67% Finalizados'),
                _LegendItem(color: AppTheme.infoColor, label: '23% En Proceso'),
                _LegendItem(color: AppTheme.errorColor, label: '10% Rechazados'),
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
