// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationSettings {

/// 伙伴开始运动时推送我。
 bool get partnerStartEnabled;/// 静音的房间:这些房间里伙伴开始运动不推送。
 Set<String> get mutedRoomIds;
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<NotificationSettings> get copyWith => _$NotificationSettingsCopyWithImpl<NotificationSettings>(this as NotificationSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettings&&(identical(other.partnerStartEnabled, partnerStartEnabled) || other.partnerStartEnabled == partnerStartEnabled)&&const DeepCollectionEquality().equals(other.mutedRoomIds, mutedRoomIds));
}


@override
int get hashCode => Object.hash(runtimeType,partnerStartEnabled,const DeepCollectionEquality().hash(mutedRoomIds));

@override
String toString() {
  return 'NotificationSettings(partnerStartEnabled: $partnerStartEnabled, mutedRoomIds: $mutedRoomIds)';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsCopyWith<$Res>  {
  factory $NotificationSettingsCopyWith(NotificationSettings value, $Res Function(NotificationSettings) _then) = _$NotificationSettingsCopyWithImpl;
@useResult
$Res call({
 bool partnerStartEnabled, Set<String> mutedRoomIds
});




}
/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._self, this._then);

  final NotificationSettings _self;
  final $Res Function(NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? partnerStartEnabled = null,Object? mutedRoomIds = null,}) {
  return _then(_self.copyWith(
partnerStartEnabled: null == partnerStartEnabled ? _self.partnerStartEnabled : partnerStartEnabled // ignore: cast_nullable_to_non_nullable
as bool,mutedRoomIds: null == mutedRoomIds ? _self.mutedRoomIds : mutedRoomIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationSettings].
extension NotificationSettingsPatterns on NotificationSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettings value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool partnerStartEnabled,  Set<String> mutedRoomIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.partnerStartEnabled,_that.mutedRoomIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool partnerStartEnabled,  Set<String> mutedRoomIds)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings():
return $default(_that.partnerStartEnabled,_that.mutedRoomIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool partnerStartEnabled,  Set<String> mutedRoomIds)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.partnerStartEnabled,_that.mutedRoomIds);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationSettings extends NotificationSettings {
  const _NotificationSettings({this.partnerStartEnabled = true, final  Set<String> mutedRoomIds = const <String>{}}): _mutedRoomIds = mutedRoomIds,super._();
  

/// 伙伴开始运动时推送我。
@override@JsonKey() final  bool partnerStartEnabled;
/// 静音的房间:这些房间里伙伴开始运动不推送。
 final  Set<String> _mutedRoomIds;
/// 静音的房间:这些房间里伙伴开始运动不推送。
@override@JsonKey() Set<String> get mutedRoomIds {
  if (_mutedRoomIds is EqualUnmodifiableSetView) return _mutedRoomIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_mutedRoomIds);
}


/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsCopyWith<_NotificationSettings> get copyWith => __$NotificationSettingsCopyWithImpl<_NotificationSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettings&&(identical(other.partnerStartEnabled, partnerStartEnabled) || other.partnerStartEnabled == partnerStartEnabled)&&const DeepCollectionEquality().equals(other._mutedRoomIds, _mutedRoomIds));
}


@override
int get hashCode => Object.hash(runtimeType,partnerStartEnabled,const DeepCollectionEquality().hash(_mutedRoomIds));

@override
String toString() {
  return 'NotificationSettings(partnerStartEnabled: $partnerStartEnabled, mutedRoomIds: $mutedRoomIds)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsCopyWith<$Res> implements $NotificationSettingsCopyWith<$Res> {
  factory _$NotificationSettingsCopyWith(_NotificationSettings value, $Res Function(_NotificationSettings) _then) = __$NotificationSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool partnerStartEnabled, Set<String> mutedRoomIds
});




}
/// @nodoc
class __$NotificationSettingsCopyWithImpl<$Res>
    implements _$NotificationSettingsCopyWith<$Res> {
  __$NotificationSettingsCopyWithImpl(this._self, this._then);

  final _NotificationSettings _self;
  final $Res Function(_NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? partnerStartEnabled = null,Object? mutedRoomIds = null,}) {
  return _then(_NotificationSettings(
partnerStartEnabled: null == partnerStartEnabled ? _self.partnerStartEnabled : partnerStartEnabled // ignore: cast_nullable_to_non_nullable
as bool,mutedRoomIds: null == mutedRoomIds ? _self._mutedRoomIds : mutedRoomIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
