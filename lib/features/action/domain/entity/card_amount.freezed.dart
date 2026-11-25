// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_amount.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CardAmount {

 String get kind; num get value; String get unit;
/// Create a copy of CardAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardAmountCopyWith<CardAmount> get copyWith => _$CardAmountCopyWithImpl<CardAmount>(this as CardAmount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardAmount&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,kind,value,unit);

@override
String toString() {
  return 'CardAmount(kind: $kind, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $CardAmountCopyWith<$Res>  {
  factory $CardAmountCopyWith(CardAmount value, $Res Function(CardAmount) _then) = _$CardAmountCopyWithImpl;
@useResult
$Res call({
 String kind, num value, String unit
});




}
/// @nodoc
class _$CardAmountCopyWithImpl<$Res>
    implements $CardAmountCopyWith<$Res> {
  _$CardAmountCopyWithImpl(this._self, this._then);

  final CardAmount _self;
  final $Res Function(CardAmount) _then;

/// Create a copy of CardAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? value = null,Object? unit = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CardAmount].
extension CardAmountPatterns on CardAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardAmount value)  $default,){
final _that = this;
switch (_that) {
case _CardAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardAmount value)?  $default,){
final _that = this;
switch (_that) {
case _CardAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  num value,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardAmount() when $default != null:
return $default(_that.kind,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  num value,  String unit)  $default,) {final _that = this;
switch (_that) {
case _CardAmount():
return $default(_that.kind,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  num value,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _CardAmount() when $default != null:
return $default(_that.kind,_that.value,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _CardAmount extends CardAmount {
  const _CardAmount({required this.kind, required this.value, required this.unit}): super._();
  

@override final  String kind;
@override final  num value;
@override final  String unit;

/// Create a copy of CardAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardAmountCopyWith<_CardAmount> get copyWith => __$CardAmountCopyWithImpl<_CardAmount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardAmount&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,kind,value,unit);

@override
String toString() {
  return 'CardAmount(kind: $kind, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$CardAmountCopyWith<$Res> implements $CardAmountCopyWith<$Res> {
  factory _$CardAmountCopyWith(_CardAmount value, $Res Function(_CardAmount) _then) = __$CardAmountCopyWithImpl;
@override @useResult
$Res call({
 String kind, num value, String unit
});




}
/// @nodoc
class __$CardAmountCopyWithImpl<$Res>
    implements _$CardAmountCopyWith<$Res> {
  __$CardAmountCopyWithImpl(this._self, this._then);

  final _CardAmount _self;
  final $Res Function(_CardAmount) _then;

/// Create a copy of CardAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? value = null,Object? unit = null,}) {
  return _then(_CardAmount(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
