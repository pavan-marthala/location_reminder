# Testing Strategy & Guidelines

This document details the testing architecture, configurations, and strategies to verify the functionality, reliability, and stability of the Location Reminders application.

---

## 1. Testing Philosophy

*   **Logic First**: Prioritize testing business logic (BLoCs, UseCases, Repositories) over complex UI widget tree tests. Business logic governs the app's behavior.
*   **Decoupled Dependencies**: Always mock external resources (databases, platform APIs, network) to keep tests fast, hermetic, and deterministic.
*   **Arrange-Act-Assert (AAA)**: Structure every test block following the AAA pattern:
    *   **Arrange**: Set up the system under test (SUT), inputs, and mock behaviors.
    *   **Act**: Execute the function or trigger the event under test.
    *   **Assert**: Verify that the actual output matches the expected outcome.

---

## 2. Directory Layout for Tests

The `test` directory must mirror the structure of the `lib` directory. This makes finding tests for specific features intuitive.

```text
test/
├── core/
│   └── services/                 # Tests for global services
└── features/
    └── reminders/                # Example feature tests
        ├── data/
        │   ├── datasources/      # Local database / storage tests
        │   └── repositories/     # Repository implementation tests
        ├── domain/
        │   └── usecases/         # Business logic usecase tests
        └── presentation/
            ├── blocs/            # BLoC state-transition tests
            └── widgets/          # Individual widget rendering/interaction tests
```

---

## 3. Recommended Test Frameworks & Packages

*   **`flutter_test`**: The core package provided by the Flutter SDK. Used for assertion, widget construction, and test management.
*   **`bloc_test`**: Specialized library for testing BLoCs. Simplifies verifying stream transitions and state emissions.
*   **`mocktail`**: A mock library for Dart that does not require code generation. Ideal for mocking interfaces and stubbing behaviors.

---

## 4. Unit Testing (UseCases & Repositories)

Unit tests focus on testing a single class or function in isolation.

### Example: Usecase Test using Mocktail

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminders/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:reminders/features/reminders/domain/usecases/get_active_reminders_usecase.dart';
import 'package:reminders/features/reminders/domain/entities/reminder.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late MockReminderRepository mockRepository;
  late GetActiveRemindersUseCase useCase;

  setUp(() {
    mockRepository = MockReminderRepository();
    useCase = GetActiveRemindersUseCase(mockRepository);
  });

  test('should return list of active reminders from repository', () async {
    // Arrange
    final testReminders = [
      Reminder(id: 1, title: 'Buy milk', isActive: true),
    ];
    when(() => mockRepository.getActiveReminders())
        .thenAnswer((_) async => testReminders);

    // Act
    final result = await useCase.call();

    // Assert
    expect(result, testReminders);
    verify(() => mockRepository.getActiveReminders()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
```

---

## 5. BLoC Testing

We use the `bloc_test` package to verify state flows in response to added events. Avoid testing the internal methods of a BLoC directly; test its inputs (events) and outputs (states).

### Example BLoC Test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminders/features/reminders/presentation/blocs/reminder_bloc.dart';
import 'package:reminders/features/reminders/domain/usecases/get_active_reminders_usecase.dart';
import 'package:reminders/features/reminders/domain/entities/reminder.dart';

class MockGetActiveRemindersUseCase extends Mock implements GetActiveRemindersUseCase {}

void main() {
  late MockGetActiveRemindersUseCase mockUseCase;
  late ReminderBloc reminderBloc;

  setUp(() {
    mockUseCase = MockGetActiveRemindersUseCase();
    reminderBloc = ReminderBloc(mockUseCase);
  });

  tearDown(() {
    reminderBloc.close();
  });

  blocTest<ReminderBloc, ReminderState>(
    'emits [Loading, Loaded] when LoadReminders event is added successfully',
    build: () {
      when(() => mockUseCase.call()).thenAnswer((_) async => [
        Reminder(id: 1, title: 'Doctor Appointment', isActive: true),
      ]);
      return reminderBloc;
    },
    act: (bloc) => bloc.add(const ReminderEvent.loadReminders()),
    expect: () => [
      const ReminderState.loading(),
      ReminderState.loaded([
        Reminder(id: 1, title: 'Doctor Appointment', isActive: true),
      ]),
    ],
    verify: (_) {
      verify(() => mockUseCase.call()).called(1);
    },
  );
}
```

---

## 6. Widget (UI) Testing

Widget testing ensures visual components render correctly and user interactions trigger the appropriate state actions.

### 6.1 Isolating the Widget
*   Avoid initializing actual BLoCs and routing logic inside a widget test.
*   Mock the BLoC using `mocktail` and stub its `stream` and `state`.
*   Wrap the widget under test inside a `MaterialApp` and provide a Mock BLoC using `BlocProvider.value`.

### 6.2 Example Widget Test Setup
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminders/features/reminders/presentation/blocs/reminder_bloc.dart';
import 'package:reminders/features/reminders/presentation/widgets/reminder_card.dart';

class MockReminderBloc extends Mock implements ReminderBloc {}

void main() {
  late MockReminderBloc mockBloc;

  setUp(() {
    mockBloc = MockReminderBloc();
    // Stub states to prevent null crashes
    when(() => mockBloc.state).thenReturn(const ReminderState.initial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('renders reminder details correctly', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ReminderBloc>.value(
            value: mockBloc,
            child: const ReminderCard(title: 'Water plants'),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Water plants'), findsOneWidget);
  });
}
```

---

## 7. Mocking Native Services & Platform APIs

Since this app uses native system features (Geolocator, Maps, Local Notifications, AudioPlayer), these must be mocked carefully.

*   **Geolocator**: Mock the geolocator location stream. Avoid calling native GPS hardware in tests.
*   **Notifications**: Mock `FlutterLocalNotificationsPlugin`. Check if `show` or `cancel` was called by mocking the object.
*   **AudioPlayer**: Mock the `AudioPlayer` interface and stub `play`, `stop`, or `pause` methods.
*   **Isar Database**:
    *   *Unit tests*: It is recommended to mock the Repository or local DataSource layer instead of executing real Isar schemas in tests.
    *   *Integration tests*: If you need to test the real Isar database implementation, initialize Isar in a temporary directory (e.g., using `Directory.systemTemp`) and run tests synchronously. Ensure you close the database and clear data after each test.

---

## 8. Test Command Reference

Run tests using the following commands from the root directory:

### Run All Tests
```bash
flutter test
```

### Run a Single Test File
```bash
flutter test test/features/reminders/presentation/blocs/reminder_bloc_test.dart
```

### Run Tests and Generate Coverage Data
```bash
flutter test --coverage
```

### Format and View Coverage (macOS)
```bash
# Install lcov if not installed: brew install lcov
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
