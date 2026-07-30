import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../data/models/report.dart';
import '../../../../data/models/user.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_form_elements.dart';
import '../../widgets/image_source_bottom_sheet.dart';
import '../../widgets/custom_buttons.dart';
import '../view_models/student_dashboard_view_model.dart';
import 'report_detail_view.dart';
import 'select_category_view.dart';


import 'tabs/student_incidents_tab.dart';
import '../../widgets/shared_chats_tab.dart';
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
      _viewModel.startPolling(); 
      _viewModel.syncOfflineReports();
    });
  }
  @override
  void dispose() {
    _viewModel.stopPolling(); 
    super.dispose();
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
          onReportCreated: (title, details, idEdificio, idAula, imagePaths) async {
            await _viewModel.addReport(
              title: title,
              details: details,
              idEdificio: idEdificio,
              idAula: idAula,
              reportedBy: widget.user.name,
              imagePaths: imagePaths,
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
                              n.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(n.mensaje, style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              n.formattedTime,
                              style: TextStyle(color: theme.hintColor, fontSize: 10),
                            ),
                            leading: CircleAvatar(
                              radius: 4,
                              backgroundColor: n.leido ? Colors.transparent : AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                AgoraTextButton(
                  text: 'Marcar como leídas',
                  onPressed: () {
                    _viewModel.markNotificationsAsRead();
                    Navigator.pop(context);
                  },
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

    // Envolvemos todo el Scaffold en el ListenableBuilder para que la 
    // AppBar y el BottomNavigationBar reaccionen en tiempo real.
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final unreadCount = _viewModel.notifications.where((n) => !n.leido).length;

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
          
          // Consumimos el componente extraído para mantener el build limpio
          body: _buildCurrentTab(),
          
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
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.report_gmailerrorred_outlined),
                  activeIcon: Icon(Icons.report_gmailerrorred_rounded),
                  label: 'Incidencias',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle, size: 36, color: AppTheme.primaryColor),
                  label: 'Agregar',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (_viewModel.totalUnreadChatMessages > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${_viewModel.totalUnreadChatMessages}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.chat_bubble_rounded),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Cuenta',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- COMPONENTE EXTRAÍDO ---
  // Maneja la lógica de qué pestaña mostrar basado en el índice
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return StudentIncidentsTab(
          viewModel: _viewModel,
          onShowDetail: _showReportDetail,
          // Corrección: El índice de la pestaña de Chats es 2, no 3.
          onSeeAllChats: () => setState(() => _selectedIndex = 2), 
        );
      case 2:
        return SharedChatsTab( // <-- Usamos el unificado
          viewModel: _viewModel,
          currentUser: widget.user,
          title: 'Tus Chats Activos',
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
          onSeeAllChats: () => setState(() => _selectedIndex = 2),
        );
    }
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
    List<String> imagePaths,
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
  
  // CAMBIO: Manejamos una lista en lugar de un String
  final List<XFile> _selectedImages = [];
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
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 fotografías permitidas.')),
      );
      return;
    }

    final source = await ImageSourceBottomSheet.show(context);
    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _selectedImages.add(file);
        });
      }
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
      
      // VALIDACIÓN: 1 a 3 fotos obligatorias
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes adjuntar al menos 1 fotografía de evidencia.', style: TextStyle(color: Colors.white)), 
            backgroundColor: AppTheme.errorColor
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      // CAMBIO: Extraemos los paths de la lista
      List<String> paths = _selectedImages.map((f) => f.path).toList();

      widget.onReportCreated(
        _titleController.text,
        _detailsController.text,
        _selectedEdificioId!,
        _selectedAulaId!,
        paths, // Pasamos la lista al callback
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

    final safeBottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, safeBottomPadding),
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
                                  value: edif.id,
                                  child: Text(edif.nombre, overflow: TextOverflow.ellipsis),
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
                                  value: aula.id,
                                  child: Text(aula.nombre, overflow: TextOverflow.ellipsis),
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomLabel(text: 'Evidencia Fotográfica (${_selectedImages.length}/3)'),
                  if (_selectedImages.length < 3)
                    AgoraTextButton(
                      text: '+ Agregar',
                      onPressed: _pickAndUploadImage,
                    )
                ],
              ),
              
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12, top: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.errorColor,
                                child: Icon(Icons.close, size: 14, color: Colors.white)
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                )
              else
                AgoraSecondaryButton(
                  text: 'Subir Imagen de Referencia',
                  icon: Icons.add_a_photo_outlined,
                  onPressed: _pickAndUploadImage,
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
              
              AgoraPrimaryButton(
                text: 'Publicar Registro',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}