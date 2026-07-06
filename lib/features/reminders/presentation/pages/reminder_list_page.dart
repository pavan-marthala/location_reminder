import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reminders/core/di/injection.dart';
import 'package:reminders/core/routes/app_routes.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_toast.dart';
import 'package:reminders/features/reminders/domain/entities/reminder_enums.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';
import '../widgets/reminder_card.dart';

class ReminderListPage extends StatelessWidget {
  const ReminderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ReminderBloc>()..add(const ReminderEvent.loadReminders()),
      child: const _ReminderListView(),
    );
  }
}

class _ReminderListView extends StatefulWidget {
  const _ReminderListView();

  @override
  State<_ReminderListView> createState() => _ReminderListViewState();
}

class _ReminderListViewState extends State<_ReminderListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Sync initial search query if already set in bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<ReminderBloc>();
        if (bloc.state is ReminderLoaded) {
          _searchController.text = (bloc.state as ReminderLoaded).searchQuery;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet(BuildContext context, SortOption currentSort) {
    final colors = context.appColors;
    final typography = context.appTypography;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    'Sort By',
                    style: typography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ...SortOption.values.map((option) {
                  final isSelected = option == currentSort;
                  return ListTile(
                    title: Text(
                      option.displayName,
                      style: typography.bodyLarge.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                          )
                        : null,
                    onTap: () {
                      context.read<ReminderBloc>().add(
                        ReminderEvent.changeSortOption(option: option),
                      );
                      Navigator.pop(sheetContext);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gradients = context.appGradients;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark
              ? gradients.backgroundDark
              : gradients.backgroundLight,
        ),
        child: SafeArea(
          child: BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              final SortOption activeSort = state is ReminderLoaded
                  ? state.sortBy
                  : SortOption.recentlyCreated;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row with Search and Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: typography.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search reminders...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: colors.textTertiary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<ReminderBloc>().add(
                                          const ReminderEvent.changeSearchQuery(
                                            query: '',
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: colors.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {}); // refresh suffix icon
                              context.read<ReminderBloc>().add(
                                ReminderEvent.changeSearchQuery(query: val),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.sort_rounded),
                          tooltip: 'Sort Options',
                          color: colors.textTertiary,
                          onPressed: () =>
                              _showSortBottomSheet(context, activeSort),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded),
                          tooltip: 'Settings',
                          color: colors.textTertiary,
                          onPressed: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                  ),

                  // Content Panel
                  Expanded(
                    child: BlocConsumer<ReminderBloc, ReminderState>(
                      listener: (context, state) {
                        if (state is ReminderError) {
                          showErrorToast(message: state.message);
                        }
                      },
                      builder: (context, state) {
                        if (state is ReminderLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          );
                        } else if (state is ReminderEmpty) {
                          return _buildEmptyState(context);
                        } else if (state is ReminderLoaded) {
                          final reminders = state.filteredReminders;

                          if (reminders.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: colors.textTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reminders found.',
                                      style: typography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try another search.',
                                      style: typography.bodyMedium.copyWith(
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<ReminderBloc>().add(
                                const ReminderEvent.loadReminders(),
                              );
                            },
                            color: colors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                8,
                                24,
                                100,
                              ),
                              itemCount: reminders.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final reminder = reminders[index];
                                return ReminderCard(
                                  reminder: reminder,
                                  onToggle: (enabled) {
                                    context.read<ReminderBloc>().add(
                                      ReminderEvent.toggleReminder(
                                        id: reminder.id!,
                                        isEnabled: enabled,
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    context.read<ReminderBloc>().add(
                                      ReminderEvent.deleteReminder(
                                        id: reminder.id!,
                                      ),
                                    );
                                    showSuccessToast(
                                      message: '${reminder.title} deleted',
                                    );
                                  },
                                  onTap: () async {
                                    final result = await context.push<bool>(
                                      AppRoutes.editReminder,
                                      extra: reminder,
                                    );
                                    if (result == true && context.mounted) {
                                      context.read<ReminderBloc>().add(
                                        const ReminderEvent.loadReminders(),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          );
                        } else if (state is ReminderError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: colors.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>(AppRoutes.createReminder);
          if (result == true && context.mounted) {
            context.read<ReminderBloc>().add(
              const ReminderEvent.loadReminders(),
            );
          }
        },
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'New Reminder',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isDark = context.isDark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: isDark ? 0.3 : 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/illustration_empty.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Reminders Yet',
              style: typography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a destination reminder and we’ll alert you when you’re nearby.',
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
