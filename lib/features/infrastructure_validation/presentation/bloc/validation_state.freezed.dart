// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ValidationState {
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get isAlarmPlaying => throw _privateConstructorUsedError;
  bool get isBackgroundServiceRunning => throw _privateConstructorUsedError;
  bool get isLocationStreamActive => throw _privateConstructorUsedError;
  String? get currentCoordinates => throw _privateConstructorUsedError;
  String? get latestBackgroundTick => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ValidationStateCopyWith<ValidationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ValidationStateCopyWith<$Res> {
  factory $ValidationStateCopyWith(
          ValidationState value, $Res Function(ValidationState) then) =
      _$ValidationStateCopyWithImpl<$Res, ValidationState>;
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAlarmPlaying,
      bool isBackgroundServiceRunning,
      bool isLocationStreamActive,
      String? currentCoordinates,
      String? latestBackgroundTick,
      String? errorMessage,
      bool isLoading});
}

/// @nodoc
class _$ValidationStateCopyWithImpl<$Res, $Val extends ValidationState>
    implements $ValidationStateCopyWith<$Res> {
  _$ValidationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isAlarmPlaying = null,
    Object? isBackgroundServiceRunning = null,
    Object? isLocationStreamActive = null,
    Object? currentCoordinates = freezed,
    Object? latestBackgroundTick = freezed,
    Object? errorMessage = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAlarmPlaying: null == isAlarmPlaying
          ? _value.isAlarmPlaying
          : isAlarmPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isBackgroundServiceRunning: null == isBackgroundServiceRunning
          ? _value.isBackgroundServiceRunning
          : isBackgroundServiceRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocationStreamActive: null == isLocationStreamActive
          ? _value.isLocationStreamActive
          : isLocationStreamActive // ignore: cast_nullable_to_non_nullable
              as bool,
      currentCoordinates: freezed == currentCoordinates
          ? _value.currentCoordinates
          : currentCoordinates // ignore: cast_nullable_to_non_nullable
              as String?,
      latestBackgroundTick: freezed == latestBackgroundTick
          ? _value.latestBackgroundTick
          : latestBackgroundTick // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ValidationStateImplCopyWith<$Res>
    implements $ValidationStateCopyWith<$Res> {
  factory _$$ValidationStateImplCopyWith(_$ValidationStateImpl value,
          $Res Function(_$ValidationStateImpl) then) =
      __$$ValidationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAlarmPlaying,
      bool isBackgroundServiceRunning,
      bool isLocationStreamActive,
      String? currentCoordinates,
      String? latestBackgroundTick,
      String? errorMessage,
      bool isLoading});
}

/// @nodoc
class __$$ValidationStateImplCopyWithImpl<$Res>
    extends _$ValidationStateCopyWithImpl<$Res, _$ValidationStateImpl>
    implements _$$ValidationStateImplCopyWith<$Res> {
  __$$ValidationStateImplCopyWithImpl(
      _$ValidationStateImpl _value, $Res Function(_$ValidationStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isAlarmPlaying = null,
    Object? isBackgroundServiceRunning = null,
    Object? isLocationStreamActive = null,
    Object? currentCoordinates = freezed,
    Object? latestBackgroundTick = freezed,
    Object? errorMessage = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$ValidationStateImpl(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAlarmPlaying: null == isAlarmPlaying
          ? _value.isAlarmPlaying
          : isAlarmPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isBackgroundServiceRunning: null == isBackgroundServiceRunning
          ? _value.isBackgroundServiceRunning
          : isBackgroundServiceRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocationStreamActive: null == isLocationStreamActive
          ? _value.isLocationStreamActive
          : isLocationStreamActive // ignore: cast_nullable_to_non_nullable
              as bool,
      currentCoordinates: freezed == currentCoordinates
          ? _value.currentCoordinates
          : currentCoordinates // ignore: cast_nullable_to_non_nullable
              as String?,
      latestBackgroundTick: freezed == latestBackgroundTick
          ? _value.latestBackgroundTick
          : latestBackgroundTick // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ValidationStateImpl implements _ValidationState {
  const _$ValidationStateImpl(
      {this.isInitialized = false,
      this.isAlarmPlaying = false,
      this.isBackgroundServiceRunning = false,
      this.isLocationStreamActive = false,
      this.currentCoordinates,
      this.latestBackgroundTick,
      this.errorMessage,
      this.isLoading = false});

  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool isAlarmPlaying;
  @override
  @JsonKey()
  final bool isBackgroundServiceRunning;
  @override
  @JsonKey()
  final bool isLocationStreamActive;
  @override
  final String? currentCoordinates;
  @override
  final String? latestBackgroundTick;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ValidationState(isInitialized: $isInitialized, isAlarmPlaying: $isAlarmPlaying, isBackgroundServiceRunning: $isBackgroundServiceRunning, isLocationStreamActive: $isLocationStreamActive, currentCoordinates: $currentCoordinates, latestBackgroundTick: $latestBackgroundTick, errorMessage: $errorMessage, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationStateImpl &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isAlarmPlaying, isAlarmPlaying) ||
                other.isAlarmPlaying == isAlarmPlaying) &&
            (identical(other.isBackgroundServiceRunning,
                    isBackgroundServiceRunning) ||
                other.isBackgroundServiceRunning ==
                    isBackgroundServiceRunning) &&
            (identical(other.isLocationStreamActive, isLocationStreamActive) ||
                other.isLocationStreamActive == isLocationStreamActive) &&
            (identical(other.currentCoordinates, currentCoordinates) ||
                other.currentCoordinates == currentCoordinates) &&
            (identical(other.latestBackgroundTick, latestBackgroundTick) ||
                other.latestBackgroundTick == latestBackgroundTick) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isInitialized,
      isAlarmPlaying,
      isBackgroundServiceRunning,
      isLocationStreamActive,
      currentCoordinates,
      latestBackgroundTick,
      errorMessage,
      isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationStateImplCopyWith<_$ValidationStateImpl> get copyWith =>
      __$$ValidationStateImplCopyWithImpl<_$ValidationStateImpl>(
          this, _$identity);
}

abstract class _ValidationState implements ValidationState {
  const factory _ValidationState(
      {final bool isInitialized,
      final bool isAlarmPlaying,
      final bool isBackgroundServiceRunning,
      final bool isLocationStreamActive,
      final String? currentCoordinates,
      final String? latestBackgroundTick,
      final String? errorMessage,
      final bool isLoading}) = _$ValidationStateImpl;

  @override
  bool get isInitialized;
  @override
  bool get isAlarmPlaying;
  @override
  bool get isBackgroundServiceRunning;
  @override
  bool get isLocationStreamActive;
  @override
  String? get currentCoordinates;
  @override
  String? get latestBackgroundTick;
  @override
  String? get errorMessage;
  @override
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$ValidationStateImplCopyWith<_$ValidationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
