import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import '../entities/reminder_entity.dart';
import '../entities/reminder_enums.dart';

@lazySingleton
class ReminderQueryService {
  const ReminderQueryService();

  List<ReminderEntity> query({
    required List<ReminderEntity> reminders,
    required String searchQuery,
    required SortOption sortBy,
    Position? currentPosition,
  }) {
    // 1. Apply Search
    final cleanQuery = searchQuery.trim().toLowerCase();
    List<ReminderEntity> result = reminders;
    if (cleanQuery.isNotEmpty) {
      result = reminders.where((r) {
        return r.title.toLowerCase().contains(cleanQuery);
      }).toList();
    } else {
      result = List.from(reminders);
    }

    // 2. Apply Sorting
    result.sort((a, b) {
      switch (sortBy) {
        case SortOption.distanceNearest:
        case SortOption.distanceFarthest:
          if (currentPosition == null) {
            // Fallback to name sorting if no position is available
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
          final distA = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            b.latitude,
            b.longitude,
          );
          if (sortBy == SortOption.distanceNearest) {
            return distA.compareTo(distB);
          } else {
            return distB.compareTo(distA);
          }

        case SortOption.nameAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.nameZA:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());

        case SortOption.recentlyCreated:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.oldestCreated:
          return a.createdAt.compareTo(b.createdAt);

        case SortOption.recentlyUpdated:
          final timeA = a.updatedAt ?? a.createdAt;
          final timeB = b.updatedAt ?? b.createdAt;
          return timeB.compareTo(timeA);

        case SortOption.activeFirst:
          final isAActive = a.status == 'active' ? 0 : 1;
          final isBActive = b.status == 'active' ? 0 : 1;
          return isAActive.compareTo(isBActive);

        case SortOption.snoozedFirst:
          final isASnoozed = a.status == 'snoozed' ? 0 : 1;
          final isBSnoozed = b.status == 'snoozed' ? 0 : 1;
          return isASnoozed.compareTo(isBSnoozed);
      }
    });

    return result;
  }
}
