# Spec Delta

## Purpose

Defines how arrival at a reminder location continues to be detected when the app process is killed by the OS or an OEM battery manager, and how system fences and live location monitoring stay in sync.

## ADDED Requirements

### Requirement: System-owned arrival detection survives process death
The system SHALL maintain arrival detection independently of the Flutter process so that reaching a reminder location fires a trigger even if the app was terminated by the OS or OEM battery manager.

#### Scenario: Arrival after the process was killed
- **WHEN** the app process is killed while a reminder is active and the user later enters the reminder radius
- **THEN** the arrival is detected and a trigger is produced without the Flutter process having to be alive at the time of entry

#### Scenario: Live monitor dies alone
- **WHEN** the foreground location monitor is stopped or killed while system arrival detection is still active
- **THEN** arrival at an active reminder still produces a trigger and the monitor is restarted to resume live tracking

### Requirement: Fence set stays reconciled with active reminders
The system SHALL keep the registered arrival fences an exact reflection of the reminders that are currently eligible for monitoring, after every state change and lifecycle event.

#### Scenario: Reminder mutations update fences
- **WHEN** a reminder is created, updated, enabled, disabled, triggered, snoozed, completed, or deleted
- **THEN** the registered fences are reconciled so that only eligible reminders have fences and no fence references a stale reminder

#### Scenario: Cold start and resume reconcile fences
- **WHEN** the app is cold started, resumed after being backgrounded, or restarted after process death
- **THEN** the registered fences are rechecked against the persisted reminder set and any drift is corrected

#### Scenario: Reboot and package replacement restore fences
- **WHEN** the device reboots or the application package is replaced
- **THEN** all eligible reminders are re-registered for arrival detection without requiring the user to reopen the app

#### Scenario: No eligible reminders
- **WHEN** no reminder is eligible for monitoring
- **THEN** all registered arrival fences are removed and the foreground location monitor is stopped

### Requirement: Selectable radius matches registered fence geometry
The system SHALL register an arrival fence whose radius equals the radius the user selected, within a supported range that the user can see before saving.

#### Scenario: Radius inside the supported range
- **WHEN** a user selects a radius within the supported range and saves the reminder
- **THEN** the registered arrival fence uses that same radius and triggers only within it

#### Scenario: Radius outside the supported range
- **WHEN** a user attempts to select a radius outside the supported range
- **THEN** the selection is constrained to the supported range and the constrained value is shown to the user before saving

### Requirement: Live monitoring complements system detection
The system SHALL use live location monitoring for approaching guidance and as a fallback while the process is alive, without producing duplicate triggers for the same arrival.

#### Scenario: Approach and arrival
- **WHEN** the user is far from a reminder and moves toward it
- **THEN** live monitoring lowers sampling while far away, increases sampling as the user approaches, and does not alter the arrival condition itself

#### Scenario: Both detectors observe the same arrival
- **WHEN** a system fence and the live evaluator both observe the same reminder arrival
- **THEN** only one alarm is produced for that reminder

### Requirement: Monitoring state is recoverable after a cold start
The system SHALL restore monitoring from persisted state when the app is relaunched after process death, without duplicating work or losing reminders.

#### Scenario: Relaunch after process death
- **WHEN** the user reopens the app after the OS killed it while reminders were active
- **THEN** the persisted reminders are intact, fences are reconciled, the foreground monitor is running again, and no duplicate alarm is created
