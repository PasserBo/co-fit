// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyProgress {

 int get current; int get target; String get unit;
/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyProgressCopyWith<DailyProgress> get copyWith => _$DailyProgressCopyWithImpl<DailyProgress>(this as DailyProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyProgress&&(identical(other.current, current) || other.current == current)&&(identical(other.target, target) || other.target == target)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,current,target,unit);

@override
String toString() {
  return 'DailyProgress(current: $current, target: $target, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $DailyProgressCopyWith<$Res>  {
  factory $DailyProgressCopyWith(DailyProgress value, $Res Function(DailyProgress) _then) = _$DailyProgressCopyWithImpl;
@useResult
$Res call({
 int current, int target, String unit
});




}
/// @nodoc
class _$DailyProgressCopyWithImpl<$Res>
    implements $DailyProgressCopyWith<$Res> {
  _$DailyProgressCopyWithImpl(this._self, this._then);

  final DailyProgress _self;
  final $Res Function(DailyProgress) _then;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? current = null,Object? target = null,Object? unit = null,}) {
  return _then(_self.copyWith(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyProgress].
extension DailyProgressPatterns on DailyProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyProgress value)  $default,){
final _that = this;
switch (_that) {
case _DailyProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int current,  int target,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
return $default(_that.current,_that.target,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int current,  int target,  String unit)  $default,) {final _that = this;
switch (_that) {
case _DailyProgress():
return $default(_that.current,_that.target,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int current,  int target,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
return $default(_that.current,_that.target,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _DailyProgress extends DailyProgress {
  const _DailyProgress({required this.current, required this.target, required this.unit}): super._();
  

@override final  int current;
@override final  int target;
@override final  String unit;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyProgressCopyWith<_DailyProgress> get copyWith => __$DailyProgressCopyWithImpl<_DailyProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyProgress&&(identical(other.current, current) || other.current == current)&&(identical(other.target, target) || other.target == target)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,current,target,unit);

@override
String toString() {
  return 'DailyProgress(current: $current, target: $target, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$DailyProgressCopyWith<$Res> implements $DailyProgressCopyWith<$Res> {
  factory _$DailyProgressCopyWith(_DailyProgress value, $Res Function(_DailyProgress) _then) = __$DailyProgressCopyWithImpl;
@override @useResult
$Res call({
 int current, int target, String unit
});




}
/// @nodoc
class __$DailyProgressCopyWithImpl<$Res>
    implements _$DailyProgressCopyWith<$Res> {
  __$DailyProgressCopyWithImpl(this._self, this._then);

  final _DailyProgress _self;
  final $Res Function(_DailyProgress) _then;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? current = null,Object? target = null,Object? unit = null,}) {
  return _then(_DailyProgress(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
