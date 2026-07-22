import 'package:flutter/material.dart';
import '../../../../data/models/report.dart';
import '../../../core/theme.dart';

class SelectCategoryView extends StatefulWidget {
  const SelectCategoryView({super.key});

  @override
  State<SelectCategoryView> createState() => _SelectCategoryViewState();
}

class _SelectCategoryViewState extends State<SelectCategoryView> {
  ReportArea? _selectedArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF140D09) : AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ágora',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.normal,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seleccionar Categoría',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, selecciona el área correspondiente para dirigir tu reporte institucional.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Tarjetas de selección
              _buildCategoryCard(
                area: ReportArea.sistema,
                icon: Icons.desktop_windows_outlined,
                title: 'Sistemas',
                subtitle: 'Reporta fallas en proyectores, red, cables HDMI.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              

              const Spacer(),

              // Botón Continuar
              ElevatedButton(
                onPressed: _selectedArea == null
                    ? null
                    : () {
                        // Regresamos el área seleccionada a la pantalla anterior
                        Navigator.pop(context, _selectedArea);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required ReportArea area,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final isSelected = _selectedArea == area;
    final borderColor = isSelected 
        ? AppTheme.primaryColor 
        : (isDark ? Colors.white12 : const Color(0xFFE8E2DA));
    final bgColor = isSelected
        ? AppTheme.primaryColor.withOpacity(0.05)
        : (isDark ? const Color(0xFF261D16) : Colors.white);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedArea = area;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.15) 
                  : (isDark ? Colors.white12 : const Color(0xFFFAF5F0)),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white54 : AppTheme.primaryColor.withOpacity(0.6)),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}