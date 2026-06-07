# Coding & Architecture Conventions

This document outlines the software engineering and coding standards for the Location Reminders application. Adhering to these guidelines ensures clean, maintainable, and scalable code that aligns with Clean Architecture and SOLID design principles.

---

## 1. Directory & Clean Architecture Structure

The project follows a **Feature-First Clean Architecture** approach. Inside the `lib` folder, code is organized into distinct features, alongside a `core` directory for shared modules, configurations, and themes.

Each feature folder is structured into three layers: **Data**, **Domain**, and **Presentation**.

### Folder Layout Spec

```text
lib/
├── core/                         # Shared application-wide modules
│   ├── di/                       # Dependency Injection configuration (GetIt, Injectable)
│   ├── navigation/               # Routing configuration (GoRouter)
│   ├── services/                 # Global services (e.g., BackgroundLocationService)
│   └── utils/                    # Global utilities, helpers, and extensions
├── theme/                        # App-wide UI styling and components
│   ├── app_colors.dart           # Custom colors using ThemeExtension
│   ├── app_gradients.dart        # Custom gradients using ThemeExtension
│   ├── app_theme.dart            # ThemeData definition for Light/Dark modes
│   └── app_typography.dart       # Typography definition using ThemeExtension
├── features/                     # Feature-specific modules
│   └── reminders/                # Example feature: Reminders management
│       ├── data/                 # Data Layer: external communication, caching, persistence
│       │   ├── datasources/      # Remote API or local database (Isar) queries
│       │   ├── models/           # Data models (JSON serializable, Isar collections)
│       │   └── repositories/     # Concrete repository implementations
│       ├── domain/               # Domain Layer: core business logic (framework-independent)
│       │   ├── entities/         # Plain Dart objects representing core domain models
│       │   ├── repositories/     # Abstract repository contracts
│       │   └── usecases/         # Executable business logic operations
│       └── presentation/         # Presentation Layer: UI components and state management
│           ├── blocs/            # Feature BLoCs (Events, States, Blocs)
│           ├── screens/          # Whole-page widgets (screens/pages)
│           └── widgets/          # Small, reusable widgets specific to this feature
└── main.dart                     # App entry point
```

---

## 2. Naming Conventions

Consistency in naming makes the codebase easy to navigate and self-documenting.

### 2.1 File & Directory Naming
*   **Directories**: `snake_case` (e.g., `features/location_tracker`).
*   **Files**: `snake_case` with descriptive suffixes indicating their purpose (e.g., `reminder_repository.dart`, `reminder_bloc.dart`, `reminder_model.dart`).
*   **Generated Files**: Standard naming conventions enforced by packages (e.g., `<file>.freezed.dart`, `<file>.g.dart`, `<file>.config.dart`).

### 2.2 Class Naming
*   **Classes**: `PascalCase` matching the file name (e.g., class `ReminderRepositoryImpl` in `reminder_repository_impl.dart`).
*   **Abstract Contracts**: Standard name (e.g., `ReminderRepository`).
*   **Implementations**: Append `Impl` suffix (e.g., `ReminderRepositoryImpl`).
*   **Usecases**: Action-based names ending in the word `UseCase` (e.g., `GetActiveRemindersUseCase`).

### 2.3 Variables & Functions
*   **Variables, Parameters, and Functions**: `camelCase` (e.g., `reminderId`, `getActiveReminders()`).
*   **Private Members**: Prefix with an underscore `_` (e.g., `_audioPlayer`, `_loadReminders()`).
*   **Constants**: `camelCase` (e.g., `maxGeofenceRadius`).

---

## 3. State Management (BLoC Pattern)

We use the BLoC (Business Logic Component) pattern for handling state transitions asynchronously, separating presentation from logic.

### 3.1 BLoC Structures
*   Each BLoC must consist of three files:
    *   `<feature>_bloc.dart`: The component managing events and emitting states.
    *   `<feature>_event.dart`: Immutable class defining user interactions or system inputs.
    *   `<feature>_state.dart`: Immutable class representing the visual/data state of the UI.
*   We use **Freezed** to define events and states, leveraging its code generation for clean sealed classes and union types.

### 3.2 Code Generation for BLoC
Example structure using Freezed:

```dart
// reminder_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';
part 'reminder_bloc.freezed.dart';

@injectable
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final GetActiveRemindersUseCase _getActiveReminders;

  ReminderBloc(this._getActiveReminders) : super(const ReminderState.initial()) {
    on<ReminderEvent>((event, emit) async {
      // Event handling logic
    });
  }
}
```

### 3.3 State Transition Guidelines
*   Always structure states clearly. Avoid storing mixed state properties. Instead, use explicit states:
    *   `Initial`: App/Component starts up.
    *   `Loading`: Asynchronous operation is executing.
    *   `Loaded` / `Success`: Operation completed successfully with data.
    *   `Failure`: Operation failed, includes a user-friendly error message or code.
*   **Never** block the main event loop inside a BLoC. Perform long-running computations or IO operations asynchronously.

---

## 4. Models & Immutability (Freezed)

To guarantee type safety and prevent side effects from mutable states, all domain entities and state objects must be immutable.

### 4.1 Usage of `@freezed`
*   Use `freezed` for models that need deep copy operations (`copyWith`), structural equality checks, or JSON serialization.
*   Provide a default constructor or factory constructor containing fields.

### 4.2 Data Models vs. Domain Entities
*   **Domain Entities** (`lib/features/domain/entities/`): Clean Dart classes with absolute minimal dependencies. They define *what* the application operates on (e.g., `Reminder` entity).
*   **Data Models** (`lib/features/data/models/`): Framework-specific versions of entities (e.g., database representations for Isar, or JSON schemas for network adapters).
*   Provide extension mapper functions to translate between data models and domain entities:
    *   `ToModel`: E.g., `ReminderModel.fromEntity(Reminder entity)`
    *   `ToEntity`: E.g., `Reminder toEntity()`

---

## 5. Dependency Injection (injectable + get_it)

Dependency injection decouples class creation from implementation details, allowing for simpler unit testing and mocking.

### 5.1 Annotations Guidelines
*   **`@injectable`**: Used for short-lived factory dependencies (e.g., use cases, BLoCs). A new instance is created every time it's requested.
*   **`@lazySingleton`**: Used for long-lived, heavy dependencies that should only have one instance globally and be created on-demand (e.g., repository implementations, local data sources).
*   **`@singleton`**: Used for singletons that must be initialized immediately at startup.
*   **`@preResolve`**: Applied to asynchronous initialization functions (like opening the Isar database) that must finish before the application UI starts up.

### 5.2 External Dependencies Module
All third-party dependencies (e.g., Isar, FlutterLocalNotificationsPlugin, AudioPlayer) must be declared in a module registered under `lib/core/di/register_module.dart`:

```dart
@module
abstract class RegisterModule {
  @preResolve
  Future<Isar> get isar async => ...;

  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotifications => ...;
}
```

---

## 6. Isar Database & Local Persistence

Isar is used for fast local storage. Follow these rules to keep the database interactions safe:

*   **Collections**: Define collections using the `@collection` annotation from Isar (e.g., `@collection class ReminderModel`).
*   **Schema Registration**: All collections must be registered in the Isar initialization located in `RegisterModule`.
*   **ID Strategy**: Use `Id` type for IDs. Let Isar assign auto-incrementing integers or implement a deterministic ID generator using hash functions for off-line synchronization needs.
*   **Transactions**:
    *   Use `isar.writeTxn(...)` for all writes (insert, update, delete).
    *   Always keep transactions as short and scoped as possible to prevent thread blockages.

---

## 7. UI and Design Token Conventions

All widgets must adhere strictly to the design system configured in `lib/theme/`.

*   **Theme Extensions**: Retrieve custom tokens (like app-specific gradients, custom semantic colors, or font weights) from context extensions:
    *   Colors: `context.appColors.primary` or `context.appColors.background`
    *   Gradients: `context.appGradients.primaryGradient`
    *   Typography: `context.appTypography.bodyLarge`
*   **Stateless by Default**: Write widgets as `StatelessWidget`. Only use `StatefulWidget` when local UI state is required (e.g., handling animations, text inputs, or scroll controllers).
*   **Logical Breakdown**: If a widget's build method exceeds 100 lines, extract sub-widgets into local private widgets or distinct files to maintain readability.
