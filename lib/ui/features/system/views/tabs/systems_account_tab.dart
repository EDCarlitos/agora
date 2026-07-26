import 'package:flutter/material.dart';
import '../../../../../data/models/user.dart';
import '../../../../core/theme.dart';
import '../../../widgets/user_profile_header_card.dart';
import '../../view_models/systems_dashboard_view_model.dart';
import '../../../widgets/custom_buttons.dart';

class SystemsAccountTab extends StatelessWidget {
  final User user;
  final SystemsDashboardViewModel viewModel;
  final VoidCallback onLogout;

  const SystemsAccountTab({
    super.key,
    required this.user,
    required this.viewModel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Usamos el componente unificado que acabamos de crear
          UserProfileHeaderCard(user: user),
          
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
                          '${viewModel.myInProgressIncidents.length}',
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
                          '${viewModel.myResolvedIncidents.length}',
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
          AgoraPrimaryButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout_rounded,
            backgroundColor: Colors.red.shade700,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}