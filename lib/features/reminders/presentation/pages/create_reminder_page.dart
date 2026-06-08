import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/theme/app_colors.dart';
import 'package:reminders/core/theme/app_typography.dart';
import 'package:reminders/core/utils/app_button.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/generated/assets.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_entity.dart';
import 'package:reminders/features/reminders/domain/entities/location_selection_result.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';

class CreateReminderPage extends StatefulWidget {
  final ReminderEntity? reminderToEdit;

  const CreateReminderPage({super.key, this.reminderToEdit});

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;
  double? _selectedRadius;
  String? _locationName;
  String? _locationAddress;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminderToEdit != null) {
      final edit = widget.reminderToEdit!;
      _titleController.text = edit.title;
      _selectedLat = edit.latitude;
      _selectedLng = edit.longitude;
      _selectedRadius = edit.radiusMeters;
      _locationName = edit.locationName ?? 'Location (${edit.latitude.toStringAsFixed(4)}, ${edit.longitude.toStringAsFixed(4)})';
      _locationAddress = edit.locationAddress;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onSelectLocation() async {
    final result = await context.push<LocationSelectionResult>(
      AppRoutes.locationPicker,
      extra: {
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'radiusMeters': _selectedRadius,
      },
    );

    if (result != null) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _selectedRadius = result.radiusMeters;
        _locationName = result.locationName;
        _locationAddress = result.locationAddress;
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLat == null || _selectedLng == null || _selectedRadius == null) {
      showErrorToast(message: 'Please select a location geofence first');
      return;
    }

    setState(() => _isSaving = true);

    final reminder = widget.reminderToEdit == null
        ? ReminderEntity(
            title: _titleController.text.trim(),
            latitude: _selectedLat!,
            longitude: _selectedLng!,
            radiusMeters: _selectedRadius!,
            alarmTone: Assets.audioDaybreak,
            locationName: _locationName,
            locationAddress: _locationAddress,
            createdAt: DateTime.now(),
          )
        : widget.reminderToEdit!.copyWith(
            title: _titleController.text.trim(),
            latitude: _selectedLat!,
            longitude: _selectedLng!,
            radiusMeters: _selectedRadius!,
            locationName: _locationName,
            locationAddress: _locationAddress,
            updatedAt: DateTime.now(),
          );

    final bloc = getIt<ReminderBloc>();
    if (widget.reminderToEdit == null) {
      bloc.add(ReminderEvent.createReminder(reminder: reminder));
    } else {
      bloc.add(ReminderEvent.updateReminder(reminder: reminder));
    }

    // Listen for state change to confirm save
    bloc.stream.first.then((_) {
      if (mounted) {
        showSuccessToast(
          message: widget.reminderToEdit == null ? 'Reminder created' : 'Reminder updated',
        );
        context.pop(true);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _isSaving = false);
        showErrorToast(message: 'Failed to save reminder');
      }
    });
  }

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.round()} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;
    final isEdit = widget.reminderToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Reminder' : 'New Reminder'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark ? gradients.backgroundDark : gradients.backgroundLight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                _buildLabel('Reminder Name', typography),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    hint: 'e.g. Pick up Groceries',
                    icon: Icons.label_outline_rounded,
                    colors: colors,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (v.trim().length > 100) {
                      return 'Name must be under 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Location Summary Section
                _buildLabel('Target Location & Geofence', typography),
                const SizedBox(height: 8),
                if (_selectedLat == null) ...[
                  // Select Location Button
                  InkWell(
                    onTap: _onSelectLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_location_alt_rounded, size: 40, color: colors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Select Location on Map',
                            style: typography.bodyMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to place center and resize radius',
                            style: typography.bodySmall.copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Selection Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationName ?? 'Selected Location',
                                style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coordinates',
                                  style: typography.bodySmall.copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                                  style: typography.bodyMedium.copyWith(
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Geofence Radius',
                                  style: typography.bodySmall.copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatRadius(_selectedRadius!),
                                  style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          width: double.infinity,
                          text: 'Modify Location or Radius',
                          color: colors.secondary,
                          onPressed: _onSelectLocation,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Save button
                AppButton(
                  width: double.infinity,
                  text: isEdit ? 'Update Reminder' : 'Save Reminder',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
