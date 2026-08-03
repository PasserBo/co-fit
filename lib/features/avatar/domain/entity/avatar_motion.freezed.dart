// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'avatar_motion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AvatarMotion {

 AvatarMotionState get state;/// exercise 时按 4 类型走通用原型;其他状态可为 null。
 ActionType? get actionType; AvatarTempo get tempo;
/// Create a copy of AvatarMotion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarMotionCopyWith<AvatarMotion> get copyWith => _$AvatarMotionCopyWithImpl<AvatarMotion>(this as AvatarMotion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvatarMotion&&(identical(other.state, state) || other.state == state)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.tempo, tempo) || other.tempo == tempo));
}


@override
int get hashCode => Object.hash(runtimeType,state,actionType,tempo);

@override
String toString() {
  return 'AvatarMotion(state: $state, actionType: $actionType, tempo: $tempo)';
}


}

/// @nodoc
abstract mixin class $AvatarMotionCopyWith<$Res>  {
  factory $AvatarMotionCopyWith(AvatarMotion value, $Res Function(AvatarMotion) _then) = _$AvatarMotionCopyWithImpl;
@useResult
$Res call({
 AvatarMotionState state, ActionType? actionType, AvatarTempo tempo
});




}
/// @nodoc
class _$AvatarMotionCopyWithImpl<$Res>
    implements $AvatarMotionCopyWith<$Res> {
  _$AvatarMotionCopyWithImpl(this._self, this._then);

  final AvatarMotion _self;
  final $Res Function(AvatarMotion) _then;

/// Create a copy of AvatarMotion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? actionType = freezed,Object? tempo = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AvatarMotionState,actionType: freezed == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType?,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as AvatarTempo,
  ));
}

}


/// Adds pattern-matching-related methods to [AvatarMotion].
extension AvatarMotionPatterns on AvatarMotion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvatarMotion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvatarMotion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvatarMotion value)  $default,){
final _that = this;
switch (_that) {
case _AvatarMotion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvatarMotion value)?  $default,){
final _that = this;
switch (_that) {
case _AvatarMotion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AvatarMotionState state,  ActionType? actionType,  AvatarTempo tempo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvatarMotion() when $default != null:
return $default(_that.state,_that.actionType,_that.tempo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AvatarMotionState state,  ActionType? actionType,  AvatarTempo tempo)  $default,) {final _that = this;
switch (_that) {
case _AvatarMotion():
return $default(_that.state,_that.actionType,_that.tempo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AvatarMotionState state,  ActionType? actionType,  AvatarTempo tempo)?  $default,) {final _that = this;
switch (_that) {
case _AvatarMotion() when $default != null:
return $default(_that.state,_that.actionType,_that.tempo);case _:
  return null;

}
}

}

/// @nodoc


class _AvatarMotion implements AvatarMotion {
  const _AvatarMotion({required this.state, this.actionType, this.tempo = AvatarTempo.standard});
  

@override final  AvatarMotionState state;
/// exercise 时按 4 类型走通用原型;其他状态可为 null。
@override final  ActionType? actionType;
@override@JsonKey() final  AvatarTempo tempo;

/// Create a copy of AvatarMotion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarMotionCopyWith<_AvatarMotion> get copyWith => __$AvatarMotionCopyWithImpl<_AvatarMotion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvatarMotion&&(identical(other.state, state) || other.state == state)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.tempo, tempo) || other.tempo == tempo));
}


@override
int get hashCode => Object.hash(runtimeType,state,actionType,tempo);

@override
String toString() {
  return 'AvatarMotion(state: $state, actionType: $actionType, tempo: $tempo)';
}


}

/// @nodoc
abstract mixin class _$AvatarMotionCopyWith<$Res> implements $AvatarMotionCopyWith<$Res> {
  factory _$AvatarMotionCopyWith(_AvatarMotion value, $Res Function(_AvatarMotion) _then) = __$AvatarMotionCopyWithImpl;
@override @useResult
$Res call({
 AvatarMotionState state, ActionType? actionType, AvatarTempo tempo
});




}
/// @nodoc
class __$AvatarMotionCopyWithImpl<$Res>
    implements _$AvatarMotionCopyWith<$Res> {
  __$AvatarMotionCopyWithImpl(this._self, this._then);

  final _AvatarMotion _self;
  final $Res Function(_AvatarMotion) _then;

/// Create a copy of AvatarMotion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? actionType = freezed,Object? tempo = null,}) {
  return _then(_AvatarMotion(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AvatarMotionState,actionType: freezed == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType?,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as AvatarTempo,
  ));
}


}

// dart format on
