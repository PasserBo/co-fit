// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_sheet_layout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeSheetLayout {

/// 模块 id,按显示顺序。空 = 关闭今日面板。
 List<String> get modules;/// 冷启动进入房间页时展开。
 bool get expandOnColdStart;/// 离开 App 超过这么多分钟后回来时展开;null = 不按离开时长展开。
 int? get expandAfterAwayMinutes;/// 完成一张卡后展开(庆祝)。
 bool get expandAfterCompletion;/// 没被看到的完成,超过这么多小时不再补播庆祝。
 int get celebrationMaxAgeHours;
/// Create a copy of HomeSheetLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSheetLayoutCopyWith<HomeSheetLayout> get copyWith => _$HomeSheetLayoutCopyWithImpl<HomeSheetLayout>(this as HomeSheetLayout, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSheetLayout&&const DeepCollectionEquality().equals(other.modules, modules)&&(identical(other.expandOnColdStart, expandOnColdStart) || other.expandOnColdStart == expandOnColdStart)&&(identical(other.expandAfterAwayMinutes, expandAfterAwayMinutes) || other.expandAfterAwayMinutes == expandAfterAwayMinutes)&&(identical(other.expandAfterCompletion, expandAfterCompletion) || other.expandAfterCompletion == expandAfterCompletion)&&(identical(other.celebrationMaxAgeHours, celebrationMaxAgeHours) || other.celebrationMaxAgeHours == celebrationMaxAgeHours));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(modules),expandOnColdStart,expandAfterAwayMinutes,expandAfterCompletion,celebrationMaxAgeHours);

@override
String toString() {
  return 'HomeSheetLayout(modules: $modules, expandOnColdStart: $expandOnColdStart, expandAfterAwayMinutes: $expandAfterAwayMinutes, expandAfterCompletion: $expandAfterCompletion, celebrationMaxAgeHours: $celebrationMaxAgeHours)';
}


}

/// @nodoc
abstract mixin class $HomeSheetLayoutCopyWith<$Res>  {
  factory $HomeSheetLayoutCopyWith(HomeSheetLayout value, $Res Function(HomeSheetLayout) _then) = _$HomeSheetLayoutCopyWithImpl;
@useResult
$Res call({
 List<String> modules, bool expandOnColdStart, int? expandAfterAwayMinutes, bool expandAfterCompletion, int celebrationMaxAgeHours
});




}
/// @nodoc
class _$HomeSheetLayoutCopyWithImpl<$Res>
    implements $HomeSheetLayoutCopyWith<$Res> {
  _$HomeSheetLayoutCopyWithImpl(this._self, this._then);

  final HomeSheetLayout _self;
  final $Res Function(HomeSheetLayout) _then;

/// Create a copy of HomeSheetLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modules = null,Object? expandOnColdStart = null,Object? expandAfterAwayMinutes = freezed,Object? expandAfterCompletion = null,Object? celebrationMaxAgeHours = null,}) {
  return _then(_self.copyWith(
modules: null == modules ? _self.modules : modules // ignore: cast_nullable_to_non_nullable
as List<String>,expandOnColdStart: null == expandOnColdStart ? _self.expandOnColdStart : expandOnColdStart // ignore: cast_nullable_to_non_nullable
as bool,expandAfterAwayMinutes: freezed == expandAfterAwayMinutes ? _self.expandAfterAwayMinutes : expandAfterAwayMinutes // ignore: cast_nullable_to_non_nullable
as int?,expandAfterCompletion: null == expandAfterCompletion ? _self.expandAfterCompletion : expandAfterCompletion // ignore: cast_nullable_to_non_nullable
as bool,celebrationMaxAgeHours: null == celebrationMaxAgeHours ? _self.celebrationMaxAgeHours : celebrationMaxAgeHours // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeSheetLayout].
extension HomeSheetLayoutPatterns on HomeSheetLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSheetLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSheetLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSheetLayout value)  $default,){
final _that = this;
switch (_that) {
case _HomeSheetLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSheetLayout value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSheetLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> modules,  bool expandOnColdStart,  int? expandAfterAwayMinutes,  bool expandAfterCompletion,  int celebrationMaxAgeHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSheetLayout() when $default != null:
return $default(_that.modules,_that.expandOnColdStart,_that.expandAfterAwayMinutes,_that.expandAfterCompletion,_that.celebrationMaxAgeHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> modules,  bool expandOnColdStart,  int? expandAfterAwayMinutes,  bool expandAfterCompletion,  int celebrationMaxAgeHours)  $default,) {final _that = this;
switch (_that) {
case _HomeSheetLayout():
return $default(_that.modules,_that.expandOnColdStart,_that.expandAfterAwayMinutes,_that.expandAfterCompletion,_that.celebrationMaxAgeHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> modules,  bool expandOnColdStart,  int? expandAfterAwayMinutes,  bool expandAfterCompletion,  int celebrationMaxAgeHours)?  $default,) {final _that = this;
switch (_that) {
case _HomeSheetLayout() when $default != null:
return $default(_that.modules,_that.expandOnColdStart,_that.expandAfterAwayMinutes,_that.expandAfterCompletion,_that.celebrationMaxAgeHours);case _:
  return null;

}
}

}

/// @nodoc


class _HomeSheetLayout extends HomeSheetLayout {
  const _HomeSheetLayout({final  List<String> modules = const [HomeSheetModuleIds.recommendation], this.expandOnColdStart = true, this.expandAfterAwayMinutes = 30, this.expandAfterCompletion = true, this.celebrationMaxAgeHours = 12}): _modules = modules,super._();
  

/// 模块 id,按显示顺序。空 = 关闭今日面板。
 final  List<String> _modules;
/// 模块 id,按显示顺序。空 = 关闭今日面板。
@override@JsonKey() List<String> get modules {
  if (_modules is EqualUnmodifiableListView) return _modules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modules);
}

/// 冷启动进入房间页时展开。
@override@JsonKey() final  bool expandOnColdStart;
/// 离开 App 超过这么多分钟后回来时展开;null = 不按离开时长展开。
@override@JsonKey() final  int? expandAfterAwayMinutes;
/// 完成一张卡后展开(庆祝)。
@override@JsonKey() final  bool expandAfterCompletion;
/// 没被看到的完成,超过这么多小时不再补播庆祝。
@override@JsonKey() final  int celebrationMaxAgeHours;

/// Create a copy of HomeSheetLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSheetLayoutCopyWith<_HomeSheetLayout> get copyWith => __$HomeSheetLayoutCopyWithImpl<_HomeSheetLayout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSheetLayout&&const DeepCollectionEquality().equals(other._modules, _modules)&&(identical(other.expandOnColdStart, expandOnColdStart) || other.expandOnColdStart == expandOnColdStart)&&(identical(other.expandAfterAwayMinutes, expandAfterAwayMinutes) || other.expandAfterAwayMinutes == expandAfterAwayMinutes)&&(identical(other.expandAfterCompletion, expandAfterCompletion) || other.expandAfterCompletion == expandAfterCompletion)&&(identical(other.celebrationMaxAgeHours, celebrationMaxAgeHours) || other.celebrationMaxAgeHours == celebrationMaxAgeHours));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_modules),expandOnColdStart,expandAfterAwayMinutes,expandAfterCompletion,celebrationMaxAgeHours);

@override
String toString() {
  return 'HomeSheetLayout(modules: $modules, expandOnColdStart: $expandOnColdStart, expandAfterAwayMinutes: $expandAfterAwayMinutes, expandAfterCompletion: $expandAfterCompletion, celebrationMaxAgeHours: $celebrationMaxAgeHours)';
}


}

/// @nodoc
abstract mixin class _$HomeSheetLayoutCopyWith<$Res> implements $HomeSheetLayoutCopyWith<$Res> {
  factory _$HomeSheetLayoutCopyWith(_HomeSheetLayout value, $Res Function(_HomeSheetLayout) _then) = __$HomeSheetLayoutCopyWithImpl;
@override @useResult
$Res call({
 List<String> modules, bool expandOnColdStart, int? expandAfterAwayMinutes, bool expandAfterCompletion, int celebrationMaxAgeHours
});




}
/// @nodoc
class __$HomeSheetLayoutCopyWithImpl<$Res>
    implements _$HomeSheetLayoutCopyWith<$Res> {
  __$HomeSheetLayoutCopyWithImpl(this._self, this._then);

  final _HomeSheetLayout _self;
  final $Res Function(_HomeSheetLayout) _then;

/// Create a copy of HomeSheetLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modules = null,Object? expandOnColdStart = null,Object? expandAfterAwayMinutes = freezed,Object? expandAfterCompletion = null,Object? celebrationMaxAgeHours = null,}) {
  return _then(_HomeSheetLayout(
modules: null == modules ? _self._modules : modules // ignore: cast_nullable_to_non_nullable
as List<String>,expandOnColdStart: null == expandOnColdStart ? _self.expandOnColdStart : expandOnColdStart // ignore: cast_nullable_to_non_nullable
as bool,expandAfterAwayMinutes: freezed == expandAfterAwayMinutes ? _self.expandAfterAwayMinutes : expandAfterAwayMinutes // ignore: cast_nullable_to_non_nullable
as int?,expandAfterCompletion: null == expandAfterCompletion ? _self.expandAfterCompletion : expandAfterCompletion // ignore: cast_nullable_to_non_nullable
as bool,celebrationMaxAgeHours: null == celebrationMaxAgeHours ? _self.celebrationMaxAgeHours : celebrationMaxAgeHours // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
