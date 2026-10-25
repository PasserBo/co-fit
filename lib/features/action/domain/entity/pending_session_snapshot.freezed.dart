// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_session_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingSessionSnapshot {

 String get sessionId; String get roomId; String get userId; String get templateId; String get templateName; String get actionKey; int get durationSec; DateTime get startedAt;
/// Create a copy of PendingSessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingSessionSnapshotCopyWith<PendingSessionSnapshot> get copyWith => _$PendingSessionSnapshotCopyWithImpl<PendingSessionSnapshot>(this as PendingSessionSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingSessionSnapshot&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,templateId,templateName,actionKey,durationSec,startedAt);

@override
String toString() {
  return 'PendingSessionSnapshot(sessionId: $sessionId, roomId: $roomId, userId: $userId, templateId: $templateId, templateName: $templateName, actionKey: $actionKey, durationSec: $durationSec, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $PendingSessionSnapshotCopyWith<$Res>  {
  factory $PendingSessionSnapshotCopyWith(PendingSessionSnapshot value, $Res Function(PendingSessionSnapshot) _then) = _$PendingSessionSnapshotCopyWithImpl;
@useResult
$Res call({
 String sessionId, String roomId, String userId, String templateId, String templateName, String actionKey, int durationSec, DateTime startedAt
});




}
/// @nodoc
class _$PendingSessionSnapshotCopyWithImpl<$Res>
    implements $PendingSessionSnapshotCopyWith<$Res> {
  _$PendingSessionSnapshotCopyWithImpl(this._self, this._then);

  final PendingSessionSnapshot _self;
  final $Res Function(PendingSessionSnapshot) _then;

/// Create a copy of PendingSessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? templateId = null,Object? templateName = null,Object? actionKey = null,Object? durationSec = null,Object? startedAt = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingSessionSnapshot].
extension PendingSessionSnapshotPatterns on PendingSessionSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingSessionSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingSessionSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingSessionSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PendingSessionSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingSessionSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PendingSessionSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingSessionSnapshot() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt)  $default,) {final _that = this;
switch (_that) {
case _PendingSessionSnapshot():
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingSessionSnapshot() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PendingSessionSnapshot extends PendingSessionSnapshot {
  const _PendingSessionSnapshot({required this.sessionId, required this.roomId, required this.userId, required this.templateId, required this.templateName, required this.actionKey, required this.durationSec, required this.startedAt}): super._();
  

@override final  String sessionId;
@override final  String roomId;
@override final  String userId;
@override final  String templateId;
@override final  String templateName;
@override final  String actionKey;
@override final  int durationSec;
@override final  DateTime startedAt;

/// Create a copy of PendingSessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingSessionSnapshotCopyWith<_PendingSessionSnapshot> get copyWith => __$PendingSessionSnapshotCopyWithImpl<_PendingSessionSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingSessionSnapshot&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,templateId,templateName,actionKey,durationSec,startedAt);

@override
String toString() {
  return 'PendingSessionSnapshot(sessionId: $sessionId, roomId: $roomId, userId: $userId, templateId: $templateId, templateName: $templateName, actionKey: $actionKey, durationSec: $durationSec, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class _$PendingSessionSnapshotCopyWith<$Res> implements $PendingSessionSnapshotCopyWith<$Res> {
  factory _$PendingSessionSnapshotCopyWith(_PendingSessionSnapshot value, $Res Function(_PendingSessionSnapshot) _then) = __$PendingSessionSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String roomId, String userId, String templateId, String templateName, String actionKey, int durationSec, DateTime startedAt
});




}
/// @nodoc
class __$PendingSessionSnapshotCopyWithImpl<$Res>
    implements _$PendingSessionSnapshotCopyWith<$Res> {
  __$PendingSessionSnapshotCopyWithImpl(this._self, this._then);

  final _PendingSessionSnapshot _self;
  final $Res Function(_PendingSessionSnapshot) _then;

/// Create a copy of PendingSessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? templateId = null,Object? templateName = null,Object? actionKey = null,Object? durationSec = null,Object? startedAt = null,}) {
  return _then(_PendingSessionSnapshot(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
