// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_goal_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyGoalConfig {

 String get metric; int get defaultTarget; List<int> get choices;
/// Create a copy of DailyGoalConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyGoalConfigCopyWith<DailyGoalConfig> get copyWith => _$DailyGoalConfigCopyWithImpl<DailyGoalConfig>(this as DailyGoalConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyGoalConfig&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.defaultTarget, defaultTarget) || other.defaultTarget == defaultTarget)&&const DeepCollectionEquality().equals(other.choices, choices));
}


@override
int get hashCode => Object.hash(runtimeType,metric,defaultTarget,const DeepCollectionEquality().hash(choices));

@override
String toString() {
  return 'DailyGoalConfig(metric: $metric, defaultTarget: $defaultTarget, choices: $choices)';
}


}

/// @nodoc
abstract mixin class $DailyGoalConfigCopyWith<$Res>  {
  factory $DailyGoalConfigCopyWith(DailyGoalConfig value, $Res Function(DailyGoalConfig) _then) = _$DailyGoalConfigCopyWithImpl;
@useResult
$Res call({
 String metric, int defaultTarget, List<int> choices
});




}
/// @nodoc
class _$DailyGoalConfigCopyWithImpl<$Res>
    implements $DailyGoalConfigCopyWith<$Res> {
  _$DailyGoalConfigCopyWithImpl(this._self, this._then);

  final DailyGoalConfig _self;
  final $Res Function(DailyGoalConfig) _then;

/// Create a copy of DailyGoalConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metric = null,Object? defaultTarget = null,Object? choices = null,}) {
  return _then(_self.copyWith(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,defaultTarget: null == defaultTarget ? _self.defaultTarget : defaultTarget // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyGoalConfig].
extension DailyGoalConfigPatterns on DailyGoalConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyGoalConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyGoalConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyGoalConfig value)  $default,){
final _that = this;
switch (_that) {
case _DailyGoalConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyGoalConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DailyGoalConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String metric,  int defaultTarget,  List<int> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyGoalConfig() when $default != null:
return $default(_that.metric,_that.defaultTarget,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String metric,  int defaultTarget,  List<int> choices)  $default,) {final _that = this;
switch (_that) {
case _DailyGoalConfig():
return $default(_that.metric,_that.defaultTarget,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String metric,  int defaultTarget,  List<int> choices)?  $default,) {final _that = this;
switch (_that) {
case _DailyGoalConfig() when $default != null:
return $default(_that.metric,_that.defaultTarget,_that.choices);case _:
  return null;

}
}

}

/// @nodoc


class _DailyGoalConfig extends DailyGoalConfig {
  const _DailyGoalConfig({this.metric = DailyProgressMetricIds.cards, this.defaultTarget = 2, final  List<int> choices = const [1, 2, 3, 5, 8]}): _choices = choices,super._();
  

@override@JsonKey() final  String metric;
@override@JsonKey() final  int defaultTarget;
 final  List<int> _choices;
@override@JsonKey() List<int> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of DailyGoalConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyGoalConfigCopyWith<_DailyGoalConfig> get copyWith => __$DailyGoalConfigCopyWithImpl<_DailyGoalConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyGoalConfig&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.defaultTarget, defaultTarget) || other.defaultTarget == defaultTarget)&&const DeepCollectionEquality().equals(other._choices, _choices));
}


@override
int get hashCode => Object.hash(runtimeType,metric,defaultTarget,const DeepCollectionEquality().hash(_choices));

@override
String toString() {
  return 'DailyGoalConfig(metric: $metric, defaultTarget: $defaultTarget, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$DailyGoalConfigCopyWith<$Res> implements $DailyGoalConfigCopyWith<$Res> {
  factory _$DailyGoalConfigCopyWith(_DailyGoalConfig value, $Res Function(_DailyGoalConfig) _then) = __$DailyGoalConfigCopyWithImpl;
@override @useResult
$Res call({
 String metric, int defaultTarget, List<int> choices
});




}
/// @nodoc
class __$DailyGoalConfigCopyWithImpl<$Res>
    implements _$DailyGoalConfigCopyWith<$Res> {
  __$DailyGoalConfigCopyWithImpl(this._self, this._then);

  final _DailyGoalConfig _self;
  final $Res Function(_DailyGoalConfig) _then;

/// Create a copy of DailyGoalConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metric = null,Object? defaultTarget = null,Object? choices = null,}) {
  return _then(_DailyGoalConfig(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,defaultTarget: null == defaultTarget ? _self.defaultTarget : defaultTarget // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
