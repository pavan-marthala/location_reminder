enum ReminderCategory {
  personal,
  work,
  shopping,
  home,
  travel,
  health,
  other;

  String get displayName {
    switch (this) {
      case ReminderCategory.personal:
        return 'Personal';
      case ReminderCategory.work:
        return 'Work';
      case ReminderCategory.shopping:
        return 'Shopping';
      case ReminderCategory.home:
        return 'Home';
      case ReminderCategory.travel:
        return 'Travel';
      case ReminderCategory.health:
        return 'Health';
      case ReminderCategory.other:
        return 'Other';
    }
  }

  static ReminderCategory fromString(String? val) {
    if (val == null) return ReminderCategory.other;
    return ReminderCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ReminderCategory.other,
    );
  }
}

enum VibrationPattern {
  defaultPattern,
  strong,
  emergency;

  String get displayName {
    switch (this) {
      case VibrationPattern.defaultPattern:
        return 'Default';
      case VibrationPattern.strong:
        return 'Strong';
      case VibrationPattern.emergency:
        return 'Emergency';
    }
  }

  static VibrationPattern fromString(String? val) {
    if (val == null) return VibrationPattern.defaultPattern;
    return VibrationPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => VibrationPattern.defaultPattern,
    );
  }
}

enum ReminderStatus {
  active,
  snoozed,
  triggered,
  completed;

  String get displayName {
    switch (this) {
      case ReminderStatus.active:
        return 'Active';
      case ReminderStatus.snoozed:
        return 'Snoozed';
      case ReminderStatus.triggered:
        return 'Triggered';
      case ReminderStatus.completed:
        return 'Completed';
    }
  }

  static ReminderStatus fromString(String? val) {
    if (val == null) return ReminderStatus.active;
    return ReminderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => ReminderStatus.active,
    );
  }
}

enum SortOption {
  distanceNearest,
  distanceFarthest,
  nameAZ,
  nameZA,
  recentlyCreated,
  oldestCreated,
  recentlyUpdated,
  activeFirst,
  snoozedFirst;

  String get displayName {
    switch (this) {
      case SortOption.distanceNearest:
        return 'Distance (Nearest First)';
      case SortOption.distanceFarthest:
        return 'Distance (Farthest First)';
      case SortOption.nameAZ:
        return 'Name (A–Z)';
      case SortOption.nameZA:
        return 'Name (Z–A)';
      case SortOption.recentlyCreated:
        return 'Recently Created';
      case SortOption.oldestCreated:
        return 'Oldest Created';
      case SortOption.recentlyUpdated:
        return 'Recently Updated';
      case SortOption.activeFirst:
        return 'Active First';
      case SortOption.snoozedFirst:
        return 'Snoozed First';
    }
  }

  static SortOption fromString(String? val) {
    if (val == null) return SortOption.recentlyCreated;
    return SortOption.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SortOption.recentlyCreated,
    );
  }
}
