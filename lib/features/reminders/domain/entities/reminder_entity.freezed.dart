// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReminderEntity {
  int? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get radiusMeters => throw _privateConstructorUsedError;
  String get alarmTone => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  bool get isTriggered => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get triggeredAt => throw _privateConstructorUsedError;
  DateTime? get lastTriggeredAt => throw _privateConstructorUsedError;
  DateTime? get snoozedUntil => throw _privateConstructorUsedError;
  String? get locationName => throw _privateConstructorUsedError;
  String? get locationAddress => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReminderEntityCopyWith<ReminderEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderEntityCopyWith<$Res> {
  factory $ReminderEntityCopyWith(
          ReminderEntity value, $Res Function(ReminderEntity) then) =
      _$ReminderEntityCopyWithImpl<$Res, ReminderEntity>;
  @useResult
  $Res call(
      {int? id,
      String title,
      String? description,
      double latitude,
      double longitude,
      double radiusMeters,
      String alarmTone,
      bool isEnabled,
      bool isTriggered,
      String status,
      DateTime? triggeredAt,
      DateTime? lastTriggeredAt,
      DateTime? snoozedUntil,
      String? locationName,
      String? locationAddress,
      DateTime? completedAt,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ReminderEntityCopyWithImpl<$Res, $Val extends ReminderEntity>
    implements $ReminderEntityCopyWith<$Res> {
  _$ReminderEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radiusMeters = null,
    Object? alarmTone = null,
    Object? isEnabled = null,
    Object? isTriggered = null,
    Object? status = null,
    Object? triggeredAt = freezed,
    Object? lastTriggeredAt = freezed,
    Object? snoozedUntil = freezed,
    Object? locationName = freezed,
    Object? locationAddress = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radiusMeters: null == radiusMeters
          ? _value.radiusMeters
          : radiusMeters // ignore: cast_nullable_to_non_nullable
              as double,
      alarmTone: null == alarmTone
          ? _value.alarmTone
          : alarmTone // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isTriggered: null == isTriggered
          ? _value.isTriggered
          : isTriggered // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      triggeredAt: freezed == triggeredAt
          ? _value.triggeredAt
          : triggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastTriggeredAt: freezed == lastTriggeredAt
          ? _value.lastTriggeredAt
          : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      snoozedUntil: freezed == snoozedUntil
          ? _value.snoozedUntil
          : snoozedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationAddress: freezed == locationAddress
          ? _value.locationAddress
          : locationAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReminderEntityImplCopyWith<$Res>
    implements $ReminderEntityCopyWith<$Res> {
  factory _$$ReminderEntityImplCopyWith(_$ReminderEntityImpl value,
          $Res Function(_$ReminderEntityImpl) then) =
      __$$ReminderEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String title,
      String? description,
      double latitude,
      double longitude,
      double radiusMeters,
      String alarmTone,
      bool isEnabled,
      bool isTriggered,
      String status,
      DateTime? triggeredAt,
      DateTime? lastTriggeredAt,
      DateTime? snoozedUntil,
      String? locationName,
      String? locationAddress,
      DateTime? completedAt,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ReminderEntityImplCopyWithImpl<$Res>
    extends _$ReminderEntityCopyWithImpl<$Res, _$ReminderEntityImpl>
    implements _$$ReminderEntityImplCopyWith<$Res> {
  __$$ReminderEntityImplCopyWithImpl(
      _$ReminderEntityImpl _value, $Res Function(_$ReminderEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radiusMeters = null,
    Object? alarmTone = null,
    Object? isEnabled = null,
    Object? isTriggered = null,
    Object? status = null,
    Object? triggeredAt = freezed,
    Object? lastTriggeredAt = freezed,
    Object? snoozedUntil = freezed,
    Object? locationName = freezed,
    Object? locationAddress = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ReminderEntityImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radiusMeters: null == radiusMeters
          ? _value.radiusMeters
          : radiusMeters // ignore: cast_nullable_to_non_nullable
              as double,
      alarmTone: null == alarmTone
          ? _value.alarmTone
          : alarmTone // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isTriggered: null == isTriggered
          ? _value.isTriggered
          : isTriggered // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      triggeredAt: freezed == triggeredAt
          ? _value.triggeredAt
          : triggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastTriggeredAt: freezed == lastTriggeredAt
          ? _value.lastTriggeredAt
          : lastTriggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      snoozedUntil: freezed == snoozedUntil
          ? _value.snoozedUntil
          : snoozedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      locationAddress: freezed == locationAddress
          ? _value.locationAddress
          : locationAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ReminderEntityImpl implements _ReminderEntity {
  const _$ReminderEntityImpl(
      {this.id,
      required this.title,
      this.description,
      required this.latitude,
      required this.longitude,
      required this.radiusMeters,
      required this.alarmTone,
      this.isEnabled = true,
      this.isTriggered = false,
      this.status = 'active',
      this.triggeredAt,
      this.lastTriggeredAt,
      this.snoozedUntil,
      this.locationName,
      this.locationAddress,
      this.completedAt,
      required this.createdAt,
      this.updatedAt});

  @override
  final int? id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double radiusMeters;
  @override
  final String alarmTone;
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  @JsonKey()
  final bool isTriggered;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? triggeredAt;
  @override
  final DateTime? lastTriggeredAt;
  @override
  final DateTime? snoozedUntil;
  @override
  final String? locationName;
  @override
  final String? locationAddress;
  @override
  final DateTime? completedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ReminderEntity(id: $id, title: $title, description: $description, latitude: $latitude, longitude: $longitude, radiusMeters: $radiusMeters, alarmTone: $alarmTone, isEnabled: $isEnabled, isTriggered: $isTriggered, status: $status, triggeredAt: $triggeredAt, lastTriggeredAt: $lastTriggeredAt, snoozedUntil: $snoozedUntil, locationName: $locationName, locationAddress: $locationAddress, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReminderEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radiusMeters, radiusMeters) ||
                other.radiusMeters == radiusMeters) &&
            (identical(other.alarmTone, alarmTone) ||
                other.alarmTone == alarmTone) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.isTriggered, isTriggered) ||
                other.isTriggered == isTriggered) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.triggeredAt, triggeredAt) ||
                other.triggeredAt == triggeredAt) &&
            (identical(other.lastTriggeredAt, lastTriggeredAt) ||
                other.lastTriggeredAt == lastTriggeredAt) &&
            (identical(other.snoozedUntil, snoozedUntil) ||
                other.snoozedUntil == snoozedUntil) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.locationAddress, locationAddress) ||
                other.locationAddress == locationAddress) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      latitude,
      longitude,
      radiusMeters,
      alarmTone,
      isEnabled,
      isTriggered,
      status,
      triggeredAt,
      lastTriggeredAt,
      snoozedUntil,
      locationName,
      locationAddress,
      completedAt,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReminderEntityImplCopyWith<_$ReminderEntityImpl> get copyWith =>
      __$$ReminderEntityImplCopyWithImpl<_$ReminderEntityImpl>(
          this, _$identity);
}

abstract class _ReminderEntity implements ReminderEntity {
  const factory _ReminderEntity(
      {final int? id,
      required final String title,
      final String? description,
      required final double latitude,
      required final double longitude,
      required final double radiusMeters,
      required final String alarmTone,
      final bool isEnabled,
      final bool isTriggered,
      final String status,
      final DateTime? triggeredAt,
      final DateTime? lastTriggeredAt,
      final DateTime? snoozedUntil,
      final String? locationName,
      final String? locationAddress,
      final DateTime? completedAt,
      required final DateTime createdAt,
      final DateTime? updatedAt}) = _$ReminderEntityImpl;

  @override
  int? get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get radiusMeters;
  @override
  String get alarmTone;
  @override
  bool get isEnabled;
  @override
  bool get isTriggered;
  @override
  String get status;
  @override
  DateTime? get triggeredAt;
  @override
  DateTime? get lastTriggeredAt;
  @override
  DateTime? get snoozedUntil;
  @override
  String? get locationName;
  @override
  String? get locationAddress;
  @override
  DateTime? get completedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ReminderEntityImplCopyWith<_$ReminderEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
