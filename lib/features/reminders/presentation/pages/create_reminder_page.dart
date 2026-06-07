import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/theme/app_colors.dart';
import 'package:reminders/core/theme/app_typography.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/generated/assets.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';

class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({super.key});

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '200');

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final reminder = ReminderEntity(
      title: _titleController.text.trim(),
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
      radiusMeters: double.parse(_radiusController.text.trim()),
      alarmTone: Assets.audioDaybreak,
      createdAt: DateTime.now(),
    );

    final bloc = getIt<ReminderBloc>();
    bloc.add(ReminderEvent.createReminder(reminder: reminder));

    // Listen for state change to confirm save
    bloc.stream.first.then((_) {
      if (mounted) {
        showSuccessToast(message: 'Reminder created');
        context.pop(true);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _isSaving = false);
        showErrorToast(message: 'Failed to save reminder');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Reminder'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark
              ? gradients.backgroundDark
              : gradients.backgroundLight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                _buildLabel('Title', typography),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    hint: 'e.g. Grocery Store',
                    icon: Icons.label_outline_rounded,
                    colors: colors,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (v.trim().length > 100) {
                      return 'Title must be under 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Latitude field
                _buildLabel('Latitude', typography),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _latController,
                  decoration: _inputDecoration(
                    hint: 'e.g. 17.3850',
                    icon: Icons.swap_vert_rounded,
                    colors: colors,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Latitude is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < -90 || val > 90) return 'Must be between -90 and 90';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Longitude field
                _buildLabel('Longitude', typography),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lngController,
                  decoration: _inputDecoration(
                    hint: 'e.g. 78.4867',
                    icon: Icons.swap_horiz_rounded,
                    colors: colors,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Longitude is required';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Enter a valid number';
                    if (val < -180 || val > 180) return 'Must be between -180 and 180';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Radius field
                _buildLabel('Radius (meters)', typography),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _radiusController,
                  decoration: _inputDecoration(
                    hint: 'e.g. 200',
                    icon: Icons.radar_rounded,
                    colors: colors,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Radius is required';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Must be a positive number';
                    if (val > 50000) return 'Maximum radius is 50km';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Save button
                AppButton(
                  width: double.infinity,
                  text: 'Save Reminder',
                  color: colors.primary,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppTypography typography) {
    return Text(
      text,
      style: typography.labelLarge.copyWith(fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required AppColors colors,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.error),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
