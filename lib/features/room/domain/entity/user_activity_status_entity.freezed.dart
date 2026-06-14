// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_activity_status_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserActivityStatusEntity {

 UserActivityState get activityState; String? get actionKey; int? get durationSec; int? get remainingSec; String? get sessionId; String? get templateId; String? get templateName; int? get updatedAtEpochMs;
/// Create a copy of UserActivityStatusEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserActivityStatusEntityCopyWith<UserActivityStatusEntity> get copyWith => _$UserActivityStatusEntityCopyWithImpl<UserActivityStatusEntity>(this as UserActivityStatusEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserActivityStatusEntity&&(identical(other.activityState, activityState) || other.activityState == activityState)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.updatedAtEpochMs, updatedAtEpochMs) || other.updatedAtEpochMs == updatedAtEpochMs));
}


@override
int get hashCode => Object.hash(runtimeType,activityState,actionKey,durationSec,remainingSec,sessionId,templateId,templateName,updatedAtEpochMs);

@override
String toString() {
  return 'UserActivityStatusEntity(activityState: $activityState, actionKey: $actionKey, durationSec: $durationSec, remainingSec: $remainingSec, sessionId: $sessionId, templateId: $templateId, templateName: $templateName, updatedAtEpochMs: $updatedAtEpochMs)';
}


}

/// @nodoc
abstract mixin class $UserActivityStatusEntityCopyWith<$Res>  {
  factory $UserActivityStatusEntityCopyWith(UserActivityStatusEntity value, $Res Function(UserActivityStatusEntity) _then) = _$UserActivityStatusEntityCopyWithImpl;
@useResult
$Res call({
 UserActivityState activityState, String? actionKey, int? durationSec, int? remainingSec, String? sessionId, String? templateId, String? templateName, int? updatedAtEpochMs
});




}
/// @nodoc
class _$UserActivityStatusEntityCopyWithImpl<$Res>
    implements $UserActivityStatusEntityCopyWith<$Res> {
  _$UserActivityStatusEntityCopyWithImpl(this._self, this._then);

  final UserActivityStatusEntity _self;
  final $Res Function(UserActivityStatusEntity) _then;

/// Create a copy of UserActivityStatusEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityState = null,Object? actionKey = freezed,Object? durationSec = freezed,Object? remainingSec = freezed,Object? sessionId = freezed,Object? templateId = freezed,Object? templateName = freezed,Object? updatedAtEpochMs = freezed,}) {
  return _then(_self.copyWith(
activityState: null == activityState ? _self.activityState : activityState // ignore: cast_nullable_to_non_nullable
as UserActivityState,actionKey: freezed == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,remainingSec: freezed == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,updatedAtEpochMs: freezed == updatedAtEpochMs ? _self.updatedAtEpochMs : updatedAtEpochMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserActivityStatusEntity].
extension UserActivityStatusEntityPatterns on UserActivityStatusEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserActivityStatusEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserActivityStatusEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserActivityStatusEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserActivityStatusEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserActivityStatusEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserActivityStatusEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserActivityState activityState,  String? actionKey,  int? durationSec,  int? remainingSec,  String? sessionId,  String? templateId,  String? templateName,  int? updatedAtEpochMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserActivityStatusEntity() when $default != null:
return $default(_that.activityState,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.templateId,_that.templateName,_that.updatedAtEpochMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserActivityState activityState,  String? actionKey,  int? durationSec,  int? remainingSec,  String? sessionId,  String? templateId,  String? templateName,  int? updatedAtEpochMs)  $default,) {final _that = this;
switch (_that) {
case _UserActivityStatusEntity():
return $default(_that.activityState,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.templateId,_that.templateName,_that.updatedAtEpochMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserActivityState activityState,  String? actionKey,  int? durationSec,  int? remainingSec,  String? sessionId,  String? templateId,  String? templateName,  int? updatedAtEpochMs)?  $default,) {final _that = this;
switch (_that) {
case _UserActivityStatusEntity() when $default != null:
return $default(_that.activityState,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.templateId,_that.templateName,_that.updatedAtEpochMs);case _:
  return null;

}
}

}

/// @nodoc


class _UserActivityStatusEntity implements UserActivityStatusEntity {
  const _UserActivityStatusEntity({required this.activityState, this.actionKey, this.durationSec, this.remainingSec, this.sessionId, this.templateId, this.templateName, this.updatedAtEpochMs});
  

@override final  UserActivityState activityState;
@override final  String? actionKey;
@override final  int? durationSec;
@override final  int? remainingSec;
@override final  String? sessionId;
@override final  String? templateId;
@override final  String? templateName;
@override final  int? updatedAtEpochMs;

/// Create a copy of UserActivityStatusEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserActivityStatusEntityCopyWith<_UserActivityStatusEntity> get copyWith => __$UserActivityStatusEntityCopyWithImpl<_UserActivityStatusEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserActivityStatusEntity&&(identical(other.activityState, activityState) || other.activityState == activityState)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.updatedAtEpochMs, updatedAtEpochMs) || other.updatedAtEpochMs == updatedAtEpochMs));
}


@override
int get hashCode => Object.hash(runtimeType,activityState,actionKey,durationSec,remainingSec,sessionId,templateId,templateName,updatedAtEpochMs);

@override
String toString() {
  return 'UserActivityStatusEntity(activityState: $activityState, actionKey: $actionKey, durationSec: $durationSec, remainingSec: $remainingSec, sessionId: $sessionId, templateId: $templateId, templateName: $templateName, updatedAtEpochMs: $updatedAtEpochMs)';
}


}

/// @nodoc
abstract mixin class _$UserActivityStatusEntityCopyWith<$Res> implements $UserActivityStatusEntityCopyWith<$Res> {
  factory _$UserActivityStatusEntityCopyWith(_UserActivityStatusEntity value, $Res Function(_UserActivityStatusEntity) _then) = __$UserActivityStatusEntityCopyWithImpl;
@override @useResult
$Res call({
 UserActivityState activityState, String? actionKey, int? durationSec, int? remainingSec, String? sessionId, String? templateId, String? templateName, int? updatedAtEpochMs
});




}
/// @nodoc
class __$UserActivityStatusEntityCopyWithImpl<$Res>
    implements _$UserActivityStatusEntityCopyWith<$Res> {
  __$UserActivityStatusEntityCopyWithImpl(this._self, this._then);

  final _UserActivityStatusEntity _self;
  final $Res Function(_UserActivityStatusEntity) _then;

/// Create a copy of UserActivityStatusEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityState = null,Object? actionKey = freezed,Object? durationSec = freezed,Object? remainingSec = freezed,Object? sessionId = freezed,Object? templateId = freezed,Object? templateName = freezed,Object? updatedAtEpochMs = freezed,}) {
  return _then(_UserActivityStatusEntity(
activityState: null == activityState ? _self.activityState : activityState // ignore: cast_nullable_to_non_nullable
as UserActivityState,actionKey: freezed == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,remainingSec: freezed == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,updatedAtEpochMs: freezed == updatedAtEpochMs ? _self.updatedAtEpochMs : updatedAtEpochMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
