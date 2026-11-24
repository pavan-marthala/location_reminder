import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/services/pending_trigger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 23, 12, 0);

  Future<PendingTriggerService> serviceWith({
    int? id,
    String? writtenAt,
  }) async {
    final values = <String, Object>{};
    if (id != null) values[PendingTriggerService.keyId] = id;
    if (writtenAt != null) {
      values[PendingTriggerService.keyAt] = writtenAt;
    }
    SharedPreferences.setMockInitialValues(values);
    return PendingTriggerService(await SharedPreferences.getInstance());
  }

  test('reads a fresh envelope written by the native receiver', () async {
    final service = await serviceWith(
      id: 42,
      writtenAt: now.subtract(const Duration(seconds: 30)).toIso8601String(),
    );

    final envelope = await service.readFresh(now: now);

    expect(envelope, isNotNull);
    expect(envelope!.reminderId, 42);
  });

  test('discards and clears an envelope older than 10 minutes', () async {
    final service = await serviceWith(
      id: 42,
      writtenAt: now.subtract(const Duration(minutes: 11)).toIso8601String(),
    );

    expect(await service.readFresh(now: now), isNull);
    expect(
      SharedPreferences.getInstance().then((p) => p.getInt(PendingTriggerService.keyId)),
      completion(isNull),
    );
  });

  test('clearId only clears a matching id', () async {
    final service = await serviceWith(id: 7);

    await service.clearId(8);
    expect((await service.readFresh(now: now))?.reminderId, 7);

    await service.clearId(7);
    expect(await service.readFresh(now: now), isNull);
  });
}
