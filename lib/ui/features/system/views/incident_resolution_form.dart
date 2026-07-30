import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../ui/core/theme.dart';
import '../../widgets/custom_form_elements.dart';
import '../../widgets/custom_buttons.dart';

class IncidentResolutionForm extends StatefulWidget {
  final int incidenciaId;
  final Function(String descripcion, List<String> imagePaths) onSubmit;

  const IncidentResolutionForm({
    super.key,
    required this.incidenciaId,
    required this.onSubmit,
  });

  @override
  State<IncidentResolutionForm> createState() => _IncidentResolutionFormState();
}

class _IncidentResolutionFormState extends State<IncidentResolutionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  void _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 fotografías permitidas.')),
      );
      return;
    }
    final file = await _picker.pickImage(source: source, imageQuality: 70);
    if (file != null) {
      setState(() {
        _selectedImages.add(file);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes adjuntar al menos 1 fotografía de evidencia.', style: TextStyle(color: Colors.white)), 
            backgroundColor: AppTheme.errorColor
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);
      
      List<String> paths = _selectedImages.map((f) => f.path).toList();
      await widget.onSubmit(_descripcionController.text, paths);
      
      if (mounted) Navigator.pop(context); // Cierra el modal al terminar
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, safeBottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Finalizar Incidencia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adjunta de 1 a 3 fotografías probatorias y un comentario técnico para marcar este reporte como resuelto.', 
                style: TextStyle(fontSize: 13, color: Colors.grey)
              ),
              const SizedBox(height: 20),
              
              const CustomLabel(text: 'Comentario Explicativo'),
              CustomTextField(
                controller: _descripcionController,
                hintText: 'Ej: Se reemplazó el cable HDMI...',
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'El comentario es obligatorio' : null,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomLabel(text: 'Evidencia Fotográfica (${_selectedImages.length}/3)'),
                  if (_selectedImages.length < 3)
                    AgoraTextButton(
                      text: '+ Agregar',
                      onPressed: () => _pickImage(ImageSource.camera),
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
                ),
              const SizedBox(height: 24),

              AgoraPrimaryButton(
                text: 'Confirmar Reparación',
                isLoading: _isSubmitting,
                backgroundColor: AppTheme.successColor,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}