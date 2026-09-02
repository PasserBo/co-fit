// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_session_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActionSessionRecord {

 String get sessionId; String get roomId; String get userId; String get templateId; String get templateName; String get actionKey; int get durationSec; DateTime get startedAt; DateTime get completedAt; String get status;
/// Create a copy of ActionSessionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionSessionRecordCopyWith<ActionSessionRecord> get copyWith => _$ActionSessionRecordCopyWithImpl<ActionSessionRecord>(this as ActionSessionRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionSessionRecord&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,templateId,templateName,actionKey,durationSec,startedAt,completedAt,status);

@override
String toString() {
  return 'ActionSessionRecord(sessionId: $sessionId, roomId: $roomId, userId: $userId, templateId: $templateId, templateName: $templateName, actionKey: $actionKey, durationSec: $durationSec, startedAt: $startedAt, completedAt: $completedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $ActionSessionRecordCopyWith<$Res>  {
  factory $ActionSessionRecordCopyWith(ActionSessionRecord value, $Res Function(ActionSessionRecord) _then) = _$ActionSessionRecordCopyWithImpl;
@useResult
$Res call({
 String sessionId, String roomId, String userId, String templateId, String templateName, String actionKey, int durationSec, DateTime startedAt, DateTime completedAt, String status
});




}
/// @nodoc
class _$ActionSessionRecordCopyWithImpl<$Res>
    implements $ActionSessionRecordCopyWith<$Res> {
  _$ActionSessionRecordCopyWithImpl(this._self, this._then);

  final ActionSessionRecord _self;
  final $Res Function(ActionSessionRecord) _then;

/// Create a copy of ActionSessionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? templateId = null,Object? templateName = null,Object? actionKey = null,Object? durationSec = null,Object? startedAt = null,Object? completedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionSessionRecord].
extension ActionSessionRecordPatterns on ActionSessionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionSessionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionSessionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionSessionRecord value)  $default,){
final _that = this;
switch (_that) {
case _ActionSessionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionSessionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ActionSessionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt,  DateTime completedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionSessionRecord() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt,_that.completedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt,  DateTime completedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _ActionSessionRecord():
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt,_that.completedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String roomId,  String userId,  String templateId,  String templateName,  String actionKey,  int durationSec,  DateTime startedAt,  DateTime completedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ActionSessionRecord() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.templateId,_that.templateName,_that.actionKey,_that.durationSec,_that.startedAt,_that.completedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _ActionSessionRecord extends ActionSessionRecord {
  const _ActionSessionRecord({required this.sessionId, required this.roomId, required this.userId, required this.templateId, required this.templateName, required this.actionKey, required this.durationSec, required this.startedAt, required this.completedAt, this.status = ActionSessionRecordStatus.completed}): super._();
  

@override final  String sessionId;
@override final  String roomId;
@override final  String userId;
@override final  String templateId;
@override final  String templateName;
@override final  String actionKey;
@override final  int durationSec;
@override final  DateTime startedAt;
@override final  DateTime completedAt;
@override@JsonKey() final  String status;

/// Create a copy of ActionSessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionSessionRecordCopyWith<_ActionSessionRecord> get copyWith => __$ActionSessionRecordCopyWithImpl<_ActionSessionRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionSessionRecord&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,templateId,templateName,actionKey,durationSec,startedAt,completedAt,status);

@override
String toString() {
  return 'ActionSessionRecord(sessionId: $sessionId, roomId: $roomId, userId: $userId, templateId: $templateId, templateName: $templateName, actionKey: $actionKey, durationSec: $durationSec, startedAt: $startedAt, completedAt: $completedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ActionSessionRecordCopyWith<$Res> implements $ActionSessionRecordCopyWith<$Res> {
  factory _$ActionSessionRecordCopyWith(_ActionSessionRecord value, $Res Function(_ActionSessionRecord) _then) = __$ActionSessionRecordCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String roomId, String userId, String templateId, String templateName, String actionKey, int durationSec, DateTime startedAt, DateTime completedAt, String status
});




}
/// @nodoc
class __$ActionSessionRecordCopyWithImpl<$Res>
    implements _$ActionSessionRecordCopyWith<$Res> {
  __$ActionSessionRecordCopyWithImpl(this._self, this._then);

  final _ActionSessionRecord _self;
  final $Res Function(_ActionSessionRecord) _then;

/// Create a copy of ActionSessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? templateId = null,Object? templateName = null,Object? actionKey = null,Object? durationSec = null,Object? startedAt = null,Object? completedAt = null,Object? status = null,}) {
  return _then(_ActionSessionRecord(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,templateName: null == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
