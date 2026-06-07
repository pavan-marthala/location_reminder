// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReminderEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderEventCopyWith<$Res> {
  factory $ReminderEventCopyWith(
          ReminderEvent value, $Res Function(ReminderEvent) then) =
      _$ReminderEventCopyWithImpl<$Res, ReminderEvent>;
}

/// @nodoc
class _$ReminderEventCopyWithImpl<$Res, $Val extends ReminderEvent>
    implements $ReminderEventCopyWith<$Res> {
  _$ReminderEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadRemindersImplCopyWith<$Res> {
  factory _$$LoadRemindersImplCopyWith(
          _$LoadRemindersImpl value, $Res Function(_$LoadRemindersImpl) then) =
      __$$LoadRemindersImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadRemindersImplCopyWithImpl<$Res>
    extends _$ReminderEventCopyWithImpl<$Res, _$LoadRemindersImpl>
    implements _$$LoadRemindersImplCopyWith<$Res> {
  __$$LoadRemindersImplCopyWithImpl(
      _$LoadRemindersImpl _value, $Res Function(_$LoadRemindersImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadRemindersImpl implements LoadReminders {
  const _$LoadRemindersImpl();

  @override
  String toString() {
    return 'ReminderEvent.loadReminders()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadRemindersImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) {
    return loadReminders();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) {
    return loadReminders?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) {
    if (loadReminders != null) {
      return loadReminders();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) {
    return loadReminders(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) {
    return loadReminders?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) {
    if (loadReminders != null) {
      return loadReminders(this);
    }
    return orElse();
  }
}

abstract class LoadReminders implements ReminderEvent {
  const factory LoadReminders() = _$LoadRemindersImpl;
}

/// @nodoc
abstract class _$$CreateReminderImplCopyWith<$Res> {
  factory _$$CreateReminderImplCopyWith(_$CreateReminderImpl value,
          $Res Function(_$CreateReminderImpl) then) =
      __$$CreateReminderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ReminderEntity reminder});

  $ReminderEntityCopyWith<$Res> get reminder;
}

/// @nodoc
class __$$CreateReminderImplCopyWithImpl<$Res>
    extends _$ReminderEventCopyWithImpl<$Res, _$CreateReminderImpl>
    implements _$$CreateReminderImplCopyWith<$Res> {
  __$$CreateReminderImplCopyWithImpl(
      _$CreateReminderImpl _value, $Res Function(_$CreateReminderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reminder = null,
  }) {
    return _then(_$CreateReminderImpl(
      reminder: null == reminder
          ? _value.reminder
          : reminder // ignore: cast_nullable_to_non_nullable
              as ReminderEntity,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $ReminderEntityCopyWith<$Res> get reminder {
    return $ReminderEntityCopyWith<$Res>(_value.reminder, (value) {
      return _then(_value.copyWith(reminder: value));
    });
  }
}

/// @nodoc

class _$CreateReminderImpl implements CreateReminder {
  const _$CreateReminderImpl({required this.reminder});

  @override
  final ReminderEntity reminder;

  @override
  String toString() {
    return 'ReminderEvent.createReminder(reminder: $reminder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateReminderImpl &&
            (identical(other.reminder, reminder) ||
                other.reminder == reminder));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reminder);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateReminderImplCopyWith<_$CreateReminderImpl> get copyWith =>
      __$$CreateReminderImplCopyWithImpl<_$CreateReminderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) {
    return createReminder(reminder);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) {
    return createReminder?.call(reminder);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) {
    if (createReminder != null) {
      return createReminder(reminder);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) {
    return createReminder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) {
    return createReminder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) {
    if (createReminder != null) {
      return createReminder(this);
    }
    return orElse();
  }
}

abstract class CreateReminder implements ReminderEvent {
  const factory CreateReminder({required final ReminderEntity reminder}) =
      _$CreateReminderImpl;

  ReminderEntity get reminder;
  @JsonKey(ignore: true)
  _$$CreateReminderImplCopyWith<_$CreateReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateReminderImplCopyWith<$Res> {
  factory _$$UpdateReminderImplCopyWith(_$UpdateReminderImpl value,
          $Res Function(_$UpdateReminderImpl) then) =
      __$$UpdateReminderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ReminderEntity reminder});

  $ReminderEntityCopyWith<$Res> get reminder;
}

/// @nodoc
class __$$UpdateReminderImplCopyWithImpl<$Res>
    extends _$ReminderEventCopyWithImpl<$Res, _$UpdateReminderImpl>
    implements _$$UpdateReminderImplCopyWith<$Res> {
  __$$UpdateReminderImplCopyWithImpl(
      _$UpdateReminderImpl _value, $Res Function(_$UpdateReminderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reminder = null,
  }) {
    return _then(_$UpdateReminderImpl(
      reminder: null == reminder
          ? _value.reminder
          : reminder // ignore: cast_nullable_to_non_nullable
              as ReminderEntity,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $ReminderEntityCopyWith<$Res> get reminder {
    return $ReminderEntityCopyWith<$Res>(_value.reminder, (value) {
      return _then(_value.copyWith(reminder: value));
    });
  }
}

/// @nodoc

class _$UpdateReminderImpl implements UpdateReminder {
  const _$UpdateReminderImpl({required this.reminder});

  @override
  final ReminderEntity reminder;

  @override
  String toString() {
    return 'ReminderEvent.updateReminder(reminder: $reminder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateReminderImpl &&
            (identical(other.reminder, reminder) ||
                other.reminder == reminder));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reminder);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateReminderImplCopyWith<_$UpdateReminderImpl> get copyWith =>
      __$$UpdateReminderImplCopyWithImpl<_$UpdateReminderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) {
    return updateReminder(reminder);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) {
    return updateReminder?.call(reminder);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) {
    if (updateReminder != null) {
      return updateReminder(reminder);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) {
    return updateReminder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) {
    return updateReminder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) {
    if (updateReminder != null) {
      return updateReminder(this);
    }
    return orElse();
  }
}

abstract class UpdateReminder implements ReminderEvent {
  const factory UpdateReminder({required final ReminderEntity reminder}) =
      _$UpdateReminderImpl;

  ReminderEntity get reminder;
  @JsonKey(ignore: true)
  _$$UpdateReminderImplCopyWith<_$UpdateReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeleteReminderImplCopyWith<$Res> {
  factory _$$DeleteReminderImplCopyWith(_$DeleteReminderImpl value,
          $Res Function(_$DeleteReminderImpl) then) =
      __$$DeleteReminderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int id});
}

/// @nodoc
class __$$DeleteReminderImplCopyWithImpl<$Res>
    extends _$ReminderEventCopyWithImpl<$Res, _$DeleteReminderImpl>
    implements _$$DeleteReminderImplCopyWith<$Res> {
  __$$DeleteReminderImplCopyWithImpl(
      _$DeleteReminderImpl _value, $Res Function(_$DeleteReminderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$DeleteReminderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DeleteReminderImpl implements DeleteReminder {
  const _$DeleteReminderImpl({required this.id});

  @override
  final int id;

  @override
  String toString() {
    return 'ReminderEvent.deleteReminder(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteReminderImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteReminderImplCopyWith<_$DeleteReminderImpl> get copyWith =>
      __$$DeleteReminderImplCopyWithImpl<_$DeleteReminderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) {
    return deleteReminder(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) {
    return deleteReminder?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) {
    if (deleteReminder != null) {
      return deleteReminder(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) {
    return deleteReminder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) {
    return deleteReminder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) {
    if (deleteReminder != null) {
      return deleteReminder(this);
    }
    return orElse();
  }
}

abstract class DeleteReminder implements ReminderEvent {
  const factory DeleteReminder({required final int id}) = _$DeleteReminderImpl;

  int get id;
  @JsonKey(ignore: true)
  _$$DeleteReminderImplCopyWith<_$DeleteReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToggleReminderImplCopyWith<$Res> {
  factory _$$ToggleReminderImplCopyWith(_$ToggleReminderImpl value,
          $Res Function(_$ToggleReminderImpl) then) =
      __$$ToggleReminderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int id, bool isEnabled});
}

/// @nodoc
class __$$ToggleReminderImplCopyWithImpl<$Res>
    extends _$ReminderEventCopyWithImpl<$Res, _$ToggleReminderImpl>
    implements _$$ToggleReminderImplCopyWith<$Res> {
  __$$ToggleReminderImplCopyWithImpl(
      _$ToggleReminderImpl _value, $Res Function(_$ToggleReminderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? isEnabled = null,
  }) {
    return _then(_$ToggleReminderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ToggleReminderImpl implements ToggleReminder {
  const _$ToggleReminderImpl({required this.id, required this.isEnabled});

  @override
  final int id;
  @override
  final bool isEnabled;

  @override
  String toString() {
    return 'ReminderEvent.toggleReminder(id: $id, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToggleReminderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, isEnabled);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToggleReminderImplCopyWith<_$ToggleReminderImpl> get copyWith =>
      __$$ToggleReminderImplCopyWithImpl<_$ToggleReminderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadReminders,
    required TResult Function(ReminderEntity reminder) createReminder,
    required TResult Function(ReminderEntity reminder) updateReminder,
    required TResult Function(int id) deleteReminder,
    required TResult Function(int id, bool isEnabled) toggleReminder,
  }) {
    return toggleReminder(id, isEnabled);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadReminders,
    TResult? Function(ReminderEntity reminder)? createReminder,
    TResult? Function(ReminderEntity reminder)? updateReminder,
    TResult? Function(int id)? deleteReminder,
    TResult? Function(int id, bool isEnabled)? toggleReminder,
  }) {
    return toggleReminder?.call(id, isEnabled);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadReminders,
    TResult Function(ReminderEntity reminder)? createReminder,
    TResult Function(ReminderEntity reminder)? updateReminder,
    TResult Function(int id)? deleteReminder,
    TResult Function(int id, bool isEnabled)? toggleReminder,
    required TResult orElse(),
  }) {
    if (toggleReminder != null) {
      return toggleReminder(id, isEnabled);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadReminders value) loadReminders,
    required TResult Function(CreateReminder value) createReminder,
    required TResult Function(UpdateReminder value) updateReminder,
    required TResult Function(DeleteReminder value) deleteReminder,
    required TResult Function(ToggleReminder value) toggleReminder,
  }) {
    return toggleReminder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadReminders value)? loadReminders,
    TResult? Function(CreateReminder value)? createReminder,
    TResult? Function(UpdateReminder value)? updateReminder,
    TResult? Function(DeleteReminder value)? deleteReminder,
    TResult? Function(ToggleReminder value)? toggleReminder,
  }) {
    return toggleReminder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadReminders value)? loadReminders,
    TResult Function(CreateReminder value)? createReminder,
    TResult Function(UpdateReminder value)? updateReminder,
    TResult Function(DeleteReminder value)? deleteReminder,
    TResult Function(ToggleReminder value)? toggleReminder,
    required TResult orElse(),
  }) {
    if (toggleReminder != null) {
      return toggleReminder(this);
    }
    return orElse();
  }
}

abstract class ToggleReminder implements ReminderEvent {
  const factory ToggleReminder(
      {required final int id,
      required final bool isEnabled}) = _$ToggleReminderImpl;

  int get id;
  bool get isEnabled;
  @JsonKey(ignore: true)
  _$$ToggleReminderImplCopyWith<_$ToggleReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
