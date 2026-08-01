// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActionSession {

 String get sessionId; String get roomId; String get userId;/// 动作标识(将来映射 Rive 动画状态机)。
 String get actionKey; String? get templateId; String? get templateName; int get durationSec; DateTime get startedAt; ActionSessionStatus get status;/// active 时非空:动画/倒计时终点。
 DateTime? get endsAt;/// paused 时非空:冻结的剩余秒数。
 int? get pausedRemainingSec;/// 最后一次生效事件的时刻,乱序/陈旧事件判定用。
 DateTime get lastEventAt;
/// Create a copy of ActionSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionSessionCopyWith<ActionSession> get copyWith => _$ActionSessionCopyWithImpl<ActionSession>(this as ActionSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.pausedRemainingSec, pausedRemainingSec) || other.pausedRemainingSec == pausedRemainingSec)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,actionKey,templateId,templateName,durationSec,startedAt,status,endsAt,pausedRemainingSec,lastEventAt);

@override
String toString() {
  return 'ActionSession(sessionId: $sessionId, roomId: $roomId, userId: $userId, actionKey: $actionKey, templateId: $templateId, templateName: $templateName, durationSec: $durationSec, startedAt: $startedAt, status: $status, endsAt: $endsAt, pausedRemainingSec: $pausedRemainingSec, lastEventAt: $lastEventAt)';
}


}

/// @nodoc
abstract mixin class $ActionSessionCopyWith<$Res>  {
  factory $ActionSessionCopyWith(ActionSession value, $Res Function(ActionSession) _then) = _$ActionSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, String roomId, String userId, String actionKey, String? templateId, String? templateName, int durationSec, DateTime startedAt, ActionSessionStatus status, DateTime? endsAt, int? pausedRemainingSec, DateTime lastEventAt
});




}
/// @nodoc
class _$ActionSessionCopyWithImpl<$Res>
    implements $ActionSessionCopyWith<$Res> {
  _$ActionSessionCopyWithImpl(this._self, this._then);

  final ActionSession _self;
  final $Res Function(ActionSession) _then;

/// Create a copy of ActionSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? actionKey = null,Object? templateId = freezed,Object? templateName = freezed,Object? durationSec = null,Object? startedAt = null,Object? status = null,Object? endsAt = freezed,Object? pausedRemainingSec = freezed,Object? lastEventAt = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ActionSessionStatus,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pausedRemainingSec: freezed == pausedRemainingSec ? _self.pausedRemainingSec : pausedRemainingSec // ignore: cast_nullable_to_non_nullable
as int?,lastEventAt: null == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionSession].
extension ActionSessionPatterns on ActionSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionSession value)  $default,){
final _that = this;
switch (_that) {
case _ActionSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionSession value)?  $default,){
final _that = this;
switch (_that) {
case _ActionSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String actionKey,  String? templateId,  String? templateName,  int durationSec,  DateTime startedAt,  ActionSessionStatus status,  DateTime? endsAt,  int? pausedRemainingSec,  DateTime lastEventAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionSession() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.actionKey,_that.templateId,_that.templateName,_that.durationSec,_that.startedAt,_that.status,_that.endsAt,_that.pausedRemainingSec,_that.lastEventAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String roomId,  String userId,  String actionKey,  String? templateId,  String? templateName,  int durationSec,  DateTime startedAt,  ActionSessionStatus status,  DateTime? endsAt,  int? pausedRemainingSec,  DateTime lastEventAt)  $default,) {final _that = this;
switch (_that) {
case _ActionSession():
return $default(_that.sessionId,_that.roomId,_that.userId,_that.actionKey,_that.templateId,_that.templateName,_that.durationSec,_that.startedAt,_that.status,_that.endsAt,_that.pausedRemainingSec,_that.lastEventAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String roomId,  String userId,  String actionKey,  String? templateId,  String? templateName,  int durationSec,  DateTime startedAt,  ActionSessionStatus status,  DateTime? endsAt,  int? pausedRemainingSec,  DateTime lastEventAt)?  $default,) {final _that = this;
switch (_that) {
case _ActionSession() when $default != null:
return $default(_that.sessionId,_that.roomId,_that.userId,_that.actionKey,_that.templateId,_that.templateName,_that.durationSec,_that.startedAt,_that.status,_that.endsAt,_that.pausedRemainingSec,_that.lastEventAt);case _:
  return null;

}
}

}

/// @nodoc


class _ActionSession extends ActionSession {
  const _ActionSession({required this.sessionId, required this.roomId, required this.userId, required this.actionKey, this.templateId, this.templateName, required this.durationSec, required this.startedAt, required this.status, this.endsAt, this.pausedRemainingSec, required this.lastEventAt}): super._();
  

@override final  String sessionId;
@override final  String roomId;
@override final  String userId;
/// 动作标识(将来映射 Rive 动画状态机)。
@override final  String actionKey;
@override final  String? templateId;
@override final  String? templateName;
@override final  int durationSec;
@override final  DateTime startedAt;
@override final  ActionSessionStatus status;
/// active 时非空:动画/倒计时终点。
@override final  DateTime? endsAt;
/// paused 时非空:冻结的剩余秒数。
@override final  int? pausedRemainingSec;
/// 最后一次生效事件的时刻,乱序/陈旧事件判定用。
@override final  DateTime lastEventAt;

/// Create a copy of ActionSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionSessionCopyWith<_ActionSession> get copyWith => __$ActionSessionCopyWithImpl<_ActionSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.templateName, templateName) || other.templateName == templateName)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.pausedRemainingSec, pausedRemainingSec) || other.pausedRemainingSec == pausedRemainingSec)&&(identical(other.lastEventAt, lastEventAt) || other.lastEventAt == lastEventAt));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,roomId,userId,actionKey,templateId,templateName,durationSec,startedAt,status,endsAt,pausedRemainingSec,lastEventAt);

@override
String toString() {
  return 'ActionSession(sessionId: $sessionId, roomId: $roomId, userId: $userId, actionKey: $actionKey, templateId: $templateId, templateName: $templateName, durationSec: $durationSec, startedAt: $startedAt, status: $status, endsAt: $endsAt, pausedRemainingSec: $pausedRemainingSec, lastEventAt: $lastEventAt)';
}


}

/// @nodoc
abstract mixin class _$ActionSessionCopyWith<$Res> implements $ActionSessionCopyWith<$Res> {
  factory _$ActionSessionCopyWith(_ActionSession value, $Res Function(_ActionSession) _then) = __$ActionSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String roomId, String userId, String actionKey, String? templateId, String? templateName, int durationSec, DateTime startedAt, ActionSessionStatus status, DateTime? endsAt, int? pausedRemainingSec, DateTime lastEventAt
});




}
/// @nodoc
class __$ActionSessionCopyWithImpl<$Res>
    implements _$ActionSessionCopyWith<$Res> {
  __$ActionSessionCopyWithImpl(this._self, this._then);

  final _ActionSession _self;
  final $Res Function(_ActionSession) _then;

/// Create a copy of ActionSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? roomId = null,Object? userId = null,Object? actionKey = null,Object? templateId = freezed,Object? templateName = freezed,Object? durationSec = null,Object? startedAt = null,Object? status = null,Object? endsAt = freezed,Object? pausedRemainingSec = freezed,Object? lastEventAt = null,}) {
  return _then(_ActionSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,templateName: freezed == templateName ? _self.templateName : templateName // ignore: cast_nullable_to_non_nullable
as String?,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ActionSessionStatus,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pausedRemainingSec: freezed == pausedRemainingSec ? _self.pausedRemainingSec : pausedRemainingSec // ignore: cast_nullable_to_non_nullable
as int?,lastEventAt: null == lastEventAt ? _self.lastEventAt : lastEventAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
