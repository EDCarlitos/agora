import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_form_elements.dart';
import '../view_models/student_dashboard_view_model.dart';
import 'report_detail_view.dart';
import 'select_category_view.dart';

// Importamos las nuevas pestañas
import 'tabs/student_incidents_tab.dart';
import 'tabs/student_chats_tab.dart';
import 'tabs/student_account_tab.dart';

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
  int _selectedIndex = 0;
  final _viewModel = StudentDashboardViewModel();

  @override
  void initState() {
    super.initState();  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadReports();
      _viewModel.loadChats();
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _openCreateReportDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openCreateReportDialog() async {
    final ReportArea? selectedArea = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectCategoryView()),
    );
    if (selectedArea != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreateReportBottomSheet(
          reportedBy: widget.user.name,
          initialArea: selectedArea,
          onReportCreated: (title, details, idEdificio, idAula, imageUrl) async {
            await _viewModel.addReport(
              title: title,
              details: details,
              idEdificio: idEdificio,
              idAula: idAula,
              reportedBy: widget.user.name,
              imagePath: imageUrl,
            );
          },
        ),
      );
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final list = _viewModel.notifications;
            return AlertDialog(
              title: const Text('Notificaciones'),
              content: SizedBox(
                width: 320,
                child: list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No tienes notificaciones en este momento.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final n = list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              n['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(n['body'], style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              n['time'],
                              style: TextStyle(color: theme.hintColor, fontSize: 10),
                            ),
                            leading: CircleAvatar(
                              radius: 4,
                              backgroundColor: n['isRead'] ? Colors.transparent : AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _viewModel.markNotificationsAsRead();
                    Navigator.pop(context);
                  },
                  child: const Text('Marcar como leídas'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportDetail(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailView(report: report, currentUser: widget.user),
      ),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = _viewModel.notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ágora',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: _showNotificationsDialog,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.user.photoUrl != null
                ? NetworkImage(widget.user.photoUrl!)
                : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=60'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          switch (_selectedIndex) {
            case 0:
              return StudentIncidentsTab(
                viewModel: _viewModel,
                onShowDetail: _showReportDetail,
                onSeeAllChats: () => setState(() => _selectedIndex = 3),
              );
            case 2:
              return StudentChatsTab(
                viewModel: _viewModel,
                currentUser: widget.user,
              );
            case 3:
              return StudentAccountTab(
                viewModel: _viewModel,
                currentUser: widget.user,
                onLogout: _handleLogout,
                onShowDetail: _showReportDetail,
              );
            default:
              return StudentIncidentsTab(
                viewModel: _viewModel,
                onShowDetail: _showReportDetail,
                onSeeAllChats: () => setState(() => _selectedIndex = 3),
              );
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFEBE7),
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
              icon: Icon(Icons.report_gmailerrorred_outlined),
              activeIcon: Icon(Icons.report_gmailerrorred_rounded),
              label: 'Incidencias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 36, color: AppTheme.primaryColor),
              label: 'Agregar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
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
}

// ----------------------------------------------------
// CREATE REPORT BOTTOM SHEET
// ----------------------------------------------------
class CreateReportBottomSheet extends StatefulWidget {
  final String reportedBy;
  final ReportArea initialArea; 
  final Function(
    String title,
    String details,
    int idEdificio,
    int idAula,
    String? imageUrl,
  ) onReportCreated;

  const CreateReportBottomSheet({
    super.key,
    required this.reportedBy,
    required this.initialArea,
    required this.onReportCreated,
  });

  @override
  State<CreateReportBottomSheet> createState() => _CreateReportBottomSheetState();
}

class _CreateReportBottomSheetState extends State<CreateReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  
  bool _isSaving = false;
  String? _selectedImageUrl;
  final _picker = ImagePicker();
  
  final _viewModel = StudentDashboardViewModel();
  int? _selectedEdificioId;
  int? _selectedAulaId;

  @override
  void initState() {
    super.initState();
    _viewModel.loadUbicaciones();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _pickAndUploadImage() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D16) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Seleccionar Origen de Imagen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Cámara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          child: const Icon(Icons.photo_library_rounded, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Galería', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      setState(() {
        _selectedImageUrl = file.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error o permiso denegado: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedEdificioId != null && _selectedAulaId != null) {
      setState(() {
        _isSaving = true;
      });

      widget.onReportCreated(
        _titleController.text,
        _detailsController.text,
        _selectedEdificioId!,
        _selectedAulaId!,
        _selectedImageUrl,
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos de ubicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevo reporte de Sistemas', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              
              const CustomLabel(text: 'Título de Reporte'),
              CustomTextField(
                controller: _titleController,
                hintText: 'Ej: Proyector sin señal',
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el título de tu reporte' : null,
              ),
              const SizedBox(height: 16),
              
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoadingUbicaciones) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                  }

                  final aulasDisponibles = _selectedEdificioId != null 
                      ? _viewModel.getAulasPorEdificio(_selectedEdificioId!) 
                      : [];

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomLabel(text: 'Edificio'),
                            CustomDropdown<int>(
                              value: _selectedEdificioId,
                              hintText: 'Ej: Edificio C',
                              items: _viewModel.edificios.map<DropdownMenuItem<int>>((edif) {
                                return DropdownMenuItem<int>(
                                  value: edif['id'],
                                  child: Text(edif['nombre'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedEdificioId = val;
                                  _selectedAulaId = null;
                                });
                              },
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomLabel(text: 'Aula'),
                            CustomDropdown<int>(
                              value: _selectedAulaId,
                              hintText: 'Ej: Aula 102',
                              items: aulasDisponibles.map<DropdownMenuItem<int>>((aula) {
                                return DropdownMenuItem<int>(
                                  value: aula['id'],
                                  child: Text(aula['nombre'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: _selectedEdificioId == null ? null : (val) {
                                setState(() {
                                  _selectedAulaId = val;
                                });
                              },
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 16),
              
              const CustomLabel(text: 'Imagen de Referencia'),
              if (_selectedImageUrl != null)
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImageUrl!)), 
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageUrl = null;
                          });
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Subir Imagen de Referencia'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 16),
              
              const CustomLabel(text: 'Detalles del Reporte'),
              CustomTextField(
                controller: _detailsController,
                hintText: 'Explica los detalles sobre el incidente...',
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa los detalles' : null,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Publicar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}