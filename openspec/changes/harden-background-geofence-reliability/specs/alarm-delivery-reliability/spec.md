# Spec Delta

## Purpose

Defines the contract from a reminder arrival to a reliable, single, audible alarm, including arrivals that happen while the app process is dead and the user's first interaction with the app afterwards.

## ADDED Requirements

### Requirement: An arrival produces exactly one alarm
The system SHALL consume each reminder arrival once, regardless of which detector observed it or how many times the app process restarts.

#### Scenario: System detector hands off to the Flutter process
- **WHEN** a system arrival detector records a reminder arrival while the process is dead and then starts the Flutter process
- **THEN** the Flutter process consumes the pending arrival once and produces one alarm for that reminder

#### Scenario: Arrival consumed by the live evaluator
- **WHEN** the live evaluator triggers a reminder while a pending arrival from the system detector is recorded for the same reminder
- **THEN** the pending arrival is cleared and no second alarm is produced

#### Scenario: Stale pending arrival
- **WHEN** a pending arrival is left over from an earlier session and the reminder is already triggered, snoozed, completed, deleted, or no longer arriving
- **THEN** no alarm is produced and the stale pending arrival is cleared

### Requirement: Alarm is audible and visible without the UI process
The system SHALL present a high-priority full-screen alarm on arrival, with sound and vibration according to settings, even when the alarm screen is not open.

#### Scenario: Arrival while the app is not in the foreground
- **WHEN** a reminder triggers while the app is in the background or its process was killed
- **THEN** a full-screen alarm notification is shown and the configured alarm sound and vibration are played without requiring the user to open the app first

#### Scenario: User opens the alarm screen
- **WHEN** the user opens the alarm screen after the alarm has already started
- **THEN** the alarm keeps playing without restarting or doubling the sound, and the screen exposes stop, complete, and snooze actions

#### Scenario: Alarm stopped or completed
- **WHEN** the user stops or completes the alarm
- **THEN** sound and vibration stop immediately on every path that may be playing them and no further alarm is produced for that reminder

### Requirement: Alarm is surfaced after a cold start
The system SHALL show the user the alarm that caused a cold start and resume normal monitoring without losing the user's reminders.

#### Scenario: App launched by the alarm notification
- **WHEN** the user taps or is taken in by the alarm notification from a killed state
- **THEN** the alarm screen for that reminder is shown and monitoring is restored

#### Scenario: App opened manually after an alarm was missed
- **WHEN** the user opens the app later and a reminder was triggered while the app was dead
- **THEN** the triggered state is visible in the reminder list and no duplicate alarm is produced

### Requirement: Snooze preserves a single coherent lifecycle
The system SHALL keep the reminder's snooze state consistent across the alarm screen, the scheduled snooze notification, and the monitor so the reminder either rings once at the snooze time or resumes active monitoring.

#### Scenario: Snooze while the app is alive
- **WHEN** the user snoozes an alarm
- **THEN** audio stops, the reminder is no longer monitored as active, a timed alarm is scheduled, and the alarm screen closes

#### Scenario: Snoozed alarm fires
- **WHEN** the snooze time arrives
- **THEN** the alarm is presented and the reminder returns to a triggered state ready for completion or a further snooze

#### Scenario: Snooze expires while the process is dead
- **WHEN** the snooze time passes while the Flutter process is not running
- **THEN** the snoozed alarm is still presented and the reminder is reactivated for monitoring if it was not completed

### Requirement: Alarm failures are surfaced, not silent
The system SHALL refuse to treat monitoring as healthy when the user has denied the notifications required to present an alarm.

#### Scenario: Notifications denied
- **WHEN** notification permission is denied while reminders are active
- **THEN** the app reports that alarms cannot be delivered and directs the user to grant the permission instead of silently continuing
