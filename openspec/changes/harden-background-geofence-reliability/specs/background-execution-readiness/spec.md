# Spec Delta

## Purpose

Defines the prerequisites, health checks, and diagnostics that determine whether background arrival detection can be trusted on a device, so that silent failures caused by permissions or OEM battery policy are visible and actionable.

## ADDED Requirements

### Requirement: Monitoring requires all execution prerequisites
The system SHALL start or continue background monitoring only when all prerequisites required for reliable execution on the current platform are satisfied.

#### Scenario: All prerequisites satisfied
- **WHEN** background location access, notification permission, and Android battery-optimization exemption are all granted
- **THEN** background monitoring starts and continues for eligible reminders

#### Scenario: A prerequisite is missing
- **WHEN** any required prerequisite is denied or revoked
- **THEN** monitoring does not report itself as healthy and the user is shown which prerequisite is blocking it and how to fix it

#### Scenario: Prerequisite restored
- **WHEN** the user grants a previously missing prerequisite and returns to the app
- **THEN** readiness is re-evaluated and monitoring resumes automatically without a full app reinstall or manual restart

### Requirement: Readiness is re-evaluated at lifecycle boundaries
The system SHALL re-check execution prerequisites on app cold start, on resume, and after the user returns from system settings.

#### Scenario: Permission revoked externally
- **WHEN** the user revokes background location or notification permission in system settings and later returns to the app
- **THEN** readiness changes to unhealthy and monitoring is stopped or limited accordingly

#### Scenario: Return from settings with exemption granted
- **WHEN** the user returns from battery or location settings after granting the required access
- **THEN** the readiness state updates and monitoring is reconciled in the same visit

### Requirement: Diagnostics expose monitor health
The system SHALL provide a user-visible diagnostic view of monitor health that is sufficient to attribute a missed alarm in the field.

#### Scenario: View monitor health
- **WHEN** the user opens the diagnostics view
- **THEN** the view shows whether monitoring is enabled, whether the foreground monitor is running, the number of registered arrival fences, the last arrival event and error, the last background heartbeat, and any unmet prerequisites

#### Scenario: Stale heartbeat
- **WHEN** the background heartbeat is older than the expected interval while eligible reminders exist
- **THEN** the diagnostics view indicates that live monitoring is stale while system arrival detection may still be active

### Requirement: OEM battery restrictions are explained
The system SHALL identify devices with known aggressive battery management and guide the user to the relevant system settings.

#### Scenario: Device with OEM battery restrictions
- **WHEN** the user is on a device with known aggressive battery policies
- **THEN** the app explains the risk and offers a path to the relevant auto-launch or battery settings in addition to the standard battery-optimization exemption

#### Scenario: Guidance unavailable
- **WHEN** a vendor-specific settings screen cannot be opened
- **THEN** the app falls back to application details settings and does not fail the whole readiness flow
