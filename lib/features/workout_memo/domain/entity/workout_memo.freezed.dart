// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkoutMemo {

/// 运动记录的 id,也是文档 id。
 String get sessionId; String get templateId;/// 抄自运动记录的完成时间(按时间取最近的 memo 用)。
 DateTime get completedAt; DateTime get updatedAt;/// 感受档位的 key(文案在配置里)。
 String? get feel; String? get note;
/// Create a copy of WorkoutMemo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutMemoCopyWith<WorkoutMemo> get copyWith => _$WorkoutMemoCopyWithImpl<WorkoutMemo>(this as WorkoutMemo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutMemo&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.feel, feel) || other.feel == feel)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,templateId,completedAt,updatedAt,feel,note);

@override
String toString() {
  return 'WorkoutMemo(sessionId: $sessionId, templateId: $templateId, completedAt: $completedAt, updatedAt: $updatedAt, feel: $feel, note: $note)';
}


}

/// @nodoc
abstract mixin class $WorkoutMemoCopyWith<$Res>  {
  factory $WorkoutMemoCopyWith(WorkoutMemo value, $Res Function(WorkoutMemo) _then) = _$WorkoutMemoCopyWithImpl;
@useResult
$Res call({
 String sessionId, String templateId, DateTime completedAt, DateTime updatedAt, String? feel, String? note
});




}
/// @nodoc
class _$WorkoutMemoCopyWithImpl<$Res>
    implements $WorkoutMemoCopyWith<$Res> {
  _$WorkoutMemoCopyWithImpl(this._self, this._then);

  final WorkoutMemo _self;
  final $Res Function(WorkoutMemo) _then;

/// Create a copy of WorkoutMemo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? templateId = null,Object? completedAt = null,Object? updatedAt = null,Object? feel = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,feel: freezed == feel ? _self.feel : feel // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutMemo].
extension WorkoutMemoPatterns on WorkoutMemo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutMemo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutMemo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutMemo value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutMemo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutMemo value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutMemo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String templateId,  DateTime completedAt,  DateTime updatedAt,  String? feel,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutMemo() when $default != null:
return $default(_that.sessionId,_that.templateId,_that.completedAt,_that.updatedAt,_that.feel,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String templateId,  DateTime completedAt,  DateTime updatedAt,  String? feel,  String? note)  $default,) {final _that = this;
switch (_that) {
case _WorkoutMemo():
return $default(_that.sessionId,_that.templateId,_that.completedAt,_that.updatedAt,_that.feel,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String templateId,  DateTime completedAt,  DateTime updatedAt,  String? feel,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutMemo() when $default != null:
return $default(_that.sessionId,_that.templateId,_that.completedAt,_that.updatedAt,_that.feel,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutMemo extends WorkoutMemo {
  const _WorkoutMemo({required this.sessionId, required this.templateId, required this.completedAt, required this.updatedAt, this.feel, this.note}): super._();
  

/// 运动记录的 id,也是文档 id。
@override final  String sessionId;
@override final  String templateId;
/// 抄自运动记录的完成时间(按时间取最近的 memo 用)。
@override final  DateTime completedAt;
@override final  DateTime updatedAt;
/// 感受档位的 key(文案在配置里)。
@override final  String? feel;
@override final  String? note;

/// Create a copy of WorkoutMemo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutMemoCopyWith<_WorkoutMemo> get copyWith => __$WorkoutMemoCopyWithImpl<_WorkoutMemo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutMemo&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.feel, feel) || other.feel == feel)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,templateId,completedAt,updatedAt,feel,note);

@override
String toString() {
  return 'WorkoutMemo(sessionId: $sessionId, templateId: $templateId, completedAt: $completedAt, updatedAt: $updatedAt, feel: $feel, note: $note)';
}


}

/// @nodoc
abstract mixin class _$WorkoutMemoCopyWith<$Res> implements $WorkoutMemoCopyWith<$Res> {
  factory _$WorkoutMemoCopyWith(_WorkoutMemo value, $Res Function(_WorkoutMemo) _then) = __$WorkoutMemoCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String templateId, DateTime completedAt, DateTime updatedAt, String? feel, String? note
});




}
/// @nodoc
class __$WorkoutMemoCopyWithImpl<$Res>
    implements _$WorkoutMemoCopyWith<$Res> {
  __$WorkoutMemoCopyWithImpl(this._self, this._then);

  final _WorkoutMemo _self;
  final $Res Function(_WorkoutMemo) _then;

/// Create a copy of WorkoutMemo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? templateId = null,Object? completedAt = null,Object? updatedAt = null,Object? feel = freezed,Object? note = freezed,}) {
  return _then(_WorkoutMemo(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,feel: freezed == feel ? _self.feel : feel // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
