import 'package:flutter/material.dart';

import '../../../../data/dummy_reports.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';
import '../../../../data/models/user.dart';

import '../widgets/custom_bottom_navigation.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/report_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/summary_card.dart';

class AdminDashboardView extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

   const AdminDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
    });

  @override
  Widget build(BuildContext context) {
    final totalReports = dummyReports.length;

    final pendingReports = dummyReports
        .where((report) => report.status == ReportStatus.pendiente)
        .length;

    final inProgressReports = dummyReports
        .where((report) => report.status == ReportStatus.enProceso)
        .length;

    final resolvedReports = dummyReports
        .where((report) => report.status == ReportStatus.resuelto)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Administrativo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      bottomNavigationBar: const CustomBottomNavigation(
        currentIndex: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //----------------------------------------
              // Saludo
              //----------------------------------------

              const Text(
                "Hola, Administrador 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Gestiona y supervisa todos los reportes de la universidad.",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              //----------------------------------------
              // Buscador
              //----------------------------------------

              SearchBarWidget(
                onChanged: (value) {},
                onFilterPressed: () {},
              ),

              const SizedBox(height: 30),

              //----------------------------------------
              // Resumen General
              //----------------------------------------

              const Text(
                "Resumen General",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              SummaryCard(
                title: "Total Reportes",
                value: totalReports.toString(),
                icon: Icons.description_outlined,
                color: AppTheme.primaryColor,
              ),

              const SizedBox(height: 14),

              SummaryCard(
                title: "Pendientes",
                value: pendingReports.toString(),
                icon: Icons.pending_actions,
                color: AppTheme.pendingColor,
              ),

              const SizedBox(height: 14),

              SummaryCard(
                title: "En proceso",
                value: inProgressReports.toString(),
                icon: Icons.build_circle_outlined,
                color: AppTheme.inProgressColor,
              ),

              const SizedBox(height: 14),

              SummaryCard(
                title: "Resueltos",
                value: resolvedReports.toString(),
                icon: Icons.check_circle_outline,
                color: AppTheme.resolvedColor,
              ),

              const SizedBox(height: 30),

              //----------------------------------------
              // Reportes recientes
              //----------------------------------------

              const Text(
                "Reportes Recientes",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: dummyReports.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {

                  final report = dummyReports[index];

                  return ReportCard(
                    report: report,
                    onTap: () {},
                  );
                },
              ),

              const SizedBox(height: 30),

              //----------------------------------------
              // Accesos rápidos
              //----------------------------------------

              const Text(
                "Accesos Rápidos",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              QuickAccessCard(
                title: "Gestión de Usuarios",
                subtitle:
                    "Agregar, editar y eliminar usuarios.",
                icon: Icons.people_alt_outlined,
                color: AppTheme.primaryColor,
                onTap: () {},
              ),

              const SizedBox(height: 16),

              QuickAccessCard(
                title: "Estados de Reportes",
                subtitle:
                    "Actualizar estados de incidencias.",
                icon: Icons.assignment_turned_in_outlined,
                color: Colors.deepOrange,
                onTap: () {},
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}