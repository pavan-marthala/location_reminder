# Codebase Structure Documentation (STRUCTURE.md)

This document outlines the directory structure of the Reminders application, maps specific files and directories to their architectural roles, and defines the organizational guidelines for adding new components.

## 1. Directory Tree Skeleton

Below is the directory skeleton of the workspace. It details the existing directories alongside the planned structure for new feature modules.

```
reminders/
├── .planning/                         # Project planning and documentation folder
│   └── codebase/                      # Codebase maps and technical design docs
│       ├── ARCHITECTURE.md            # Architectural style, layers, and design principles
│       └── STRUCTURE.md               # Codebase structure and component mappings
├── android/                           # Native Android project configuration
├── ios/                               # Native iOS project configuration
├── lib/                               # Flutter Dart source code
│   ├── core/                          # Global core utilities and configurations
│   │   └── di/                        # Dependency Injection configuration
│   │       ├── injection.config.dart  # Generated DI configuration mapping (built by injectable)
│   │       ├── injection.dart         # Service Locator configuration entry point
│   │       └── register_module.dart   # Manual injection registry for third-party libraries
│   ├── features/                      # Feature-specific modules (Target Structure)
│   │   └── [feature_name]/            # Individual feature folder (e.g. reminders)
│   │       ├── data/                  # Data Layer (Infrastructure & Persistance)
│   │       │   ├── datasources/       # Data providers (local databases, API wrappers)
│   │       │   ├── models/            # DTOs (Freezed classes & Isar schemas)
│   │       │   └── repositories/      # Concrete repository implementations
│   │       ├── domain/                # Domain Layer (Pure Business Logic)
│   │       │   ├── entities/          # Plain Dart core business objects
│   │       │   ├── repositories/      # Abstract Repository contracts
│   │       │   └── usecases/          # Standard single-action business rules
│   │       └── presentation/          # Presentation Layer (User Interface)
│   │           ├── blocs/             # Blocs or Cubits managing UI state
│   │           ├── pages/             # Layout screens / page views
│   │           └── widgets/           # Small reusable view components
│   ├── theme/                         # Visual styles and Theme config
│   │   ├── app_colors.dart            # Palette extension (ThemeExtension<AppColors>)
│   │   ├── app_gradients.dart         # Gradient styles extension (ThemeExtension<AppGradients>)
│   │   ├── app_theme.dart             # ThemeData definitions for Light & Dark mode
│   │   └── app_typography.dart        # Typography styles extension (ThemeExtension<AppTypography>)
│   └── main.dart                      # Application runner and dependency initialization
├── test/                              # Testing directory
│   └── widget_test.dart               # Default Flutter widget test
├── pubspec.yaml                       # Application configuration and dependencies list
└── README.md                          # Application description and setup guidelines
```

---

## 2. Component Mapping

### A. Core Architecture Config
* **`lib/main.dart`**: The application bootstrapper. It initializes the Flutter binding environment, executes dependency registration via `configureDependencies()`, and sets up the theme configs inside the root `MaterialApp` widget.
* **`lib/core/di/injection.dart`**: Declares the `GetIt` instance globally and specifies `@InjectableInit` to auto-generate registrations.
* **`lib/core/di/register_module.dart`**: Provides pre-configured, singleton instances of third-party libraries like:
  * `Isar` (Local database for storing reminders offline)
  * `FlutterLocalNotificationsPlugin` (Triggering system-level alerts)
  * `AudioPlayer` (Playing alerting signals when reminders are triggered)

### B. Theme Management (`lib/theme/`)
App styling is modularized to support theme transitions cleanly:
* **`AppColors`**: Encapsulates HEX color schemes. Utilizes `ThemeExtension` to transition color schemes smoothly during theme shifts.
* **`AppGradients`**: Extends standard decorations to include gradients.
* **`AppTypography`**: Bridges standard Dart styles to the primary application font family ('Inter').
* **`AppTheme`**: Compiles colors, gradients, and font properties into separate light and dark `ThemeData` blocks. Includes `AppThemeContext` extension for rapid inline access (e.g. `context.appColors`).

---

## 3. Directory Guidelines for New Features

When developing a new feature (e.g., location tracking, notification scheduling, or reminders management), developers must follow the feature-first layout strictly under `lib/features/`:

1. **Feature Directory Creation**: Create a root folder named after the feature using lowercase snake_case (e.g. `reminders_dashboard`).
2. **Layer Setup**: Establish the three sub-directories: `data/`, `domain/`, and `presentation/`.
3. **Data Layer**:
   * Add models in `data/models/` using the `.freezed.dart` output structure.
   * Interface local storage methods in `data/datasources/`.
4. **Domain Layer**:
   * Entities go into `domain/entities/`.
   * Add repository interfaces in `domain/repositories/` named as `i_[feature]_repository.dart`.
5. **Presentation Layer**:
   * Use BLoC files within `presentation/blocs/` for asynchronous operations.
   * Split pages (which occupy the full screen) and widgets (small parts of the page) under their respective directories.
