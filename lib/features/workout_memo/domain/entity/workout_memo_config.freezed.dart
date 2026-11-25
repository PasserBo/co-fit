// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_memo_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemoFeel {

 String get key; String get label; String get emoji;
/// Create a copy of MemoFeel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoFeelCopyWith<MemoFeel> get copyWith => _$MemoFeelCopyWithImpl<MemoFeel>(this as MemoFeel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoFeel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.emoji, emoji) || other.emoji == emoji));
}


@override
int get hashCode => Object.hash(runtimeType,key,label,emoji);

@override
String toString() {
  return 'MemoFeel(key: $key, label: $label, emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class $MemoFeelCopyWith<$Res>  {
  factory $MemoFeelCopyWith(MemoFeel value, $Res Function(MemoFeel) _then) = _$MemoFeelCopyWithImpl;
@useResult
$Res call({
 String key, String label, String emoji
});




}
/// @nodoc
class _$MemoFeelCopyWithImpl<$Res>
    implements $MemoFeelCopyWith<$Res> {
  _$MemoFeelCopyWithImpl(this._self, this._then);

  final MemoFeel _self;
  final $Res Function(MemoFeel) _then;

/// Create a copy of MemoFeel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? emoji = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoFeel].
extension MemoFeelPatterns on MemoFeel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoFeel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoFeel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoFeel value)  $default,){
final _that = this;
switch (_that) {
case _MemoFeel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoFeel value)?  $default,){
final _that = this;
switch (_that) {
case _MemoFeel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  String emoji)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoFeel() when $default != null:
return $default(_that.key,_that.label,_that.emoji);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  String emoji)  $default,) {final _that = this;
switch (_that) {
case _MemoFeel():
return $default(_that.key,_that.label,_that.emoji);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  String emoji)?  $default,) {final _that = this;
switch (_that) {
case _MemoFeel() when $default != null:
return $default(_that.key,_that.label,_that.emoji);case _:
  return null;

}
}

}

/// @nodoc


class _MemoFeel implements MemoFeel {
  const _MemoFeel({required this.key, required this.label, this.emoji = ''});
  

@override final  String key;
@override final  String label;
@override@JsonKey() final  String emoji;

/// Create a copy of MemoFeel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoFeelCopyWith<_MemoFeel> get copyWith => __$MemoFeelCopyWithImpl<_MemoFeel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoFeel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.emoji, emoji) || other.emoji == emoji));
}


@override
int get hashCode => Object.hash(runtimeType,key,label,emoji);

@override
String toString() {
  return 'MemoFeel(key: $key, label: $label, emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class _$MemoFeelCopyWith<$Res> implements $MemoFeelCopyWith<$Res> {
  factory _$MemoFeelCopyWith(_MemoFeel value, $Res Function(_MemoFeel) _then) = __$MemoFeelCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, String emoji
});




}
/// @nodoc
class __$MemoFeelCopyWithImpl<$Res>
    implements _$MemoFeelCopyWith<$Res> {
  __$MemoFeelCopyWithImpl(this._self, this._then);

  final _MemoFeel _self;
  final $Res Function(_MemoFeel) _then;

/// Create a copy of MemoFeel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? emoji = null,}) {
  return _then(_MemoFeel(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WorkoutMemoConfig {

 List<MemoFeel> get feels;/// 完成后多久之内今日面板还问「刚才这张」。
 int get promptWindowMinutes;/// 一句话的长度上限(服务端硬上限是 500)。
 int get noteMaxLength;
/// Create a copy of WorkoutMemoConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutMemoConfigCopyWith<WorkoutMemoConfig> get copyWith => _$WorkoutMemoConfigCopyWithImpl<WorkoutMemoConfig>(this as WorkoutMemoConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutMemoConfig&&const DeepCollectionEquality().equals(other.feels, feels)&&(identical(other.promptWindowMinutes, promptWindowMinutes) || other.promptWindowMinutes == promptWindowMinutes)&&(identical(other.noteMaxLength, noteMaxLength) || other.noteMaxLength == noteMaxLength));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(feels),promptWindowMinutes,noteMaxLength);

@override
String toString() {
  return 'WorkoutMemoConfig(feels: $feels, promptWindowMinutes: $promptWindowMinutes, noteMaxLength: $noteMaxLength)';
}


}

/// @nodoc
abstract mixin class $WorkoutMemoConfigCopyWith<$Res>  {
  factory $WorkoutMemoConfigCopyWith(WorkoutMemoConfig value, $Res Function(WorkoutMemoConfig) _then) = _$WorkoutMemoConfigCopyWithImpl;
@useResult
$Res call({
 List<MemoFeel> feels, int promptWindowMinutes, int noteMaxLength
});




}
/// @nodoc
class _$WorkoutMemoConfigCopyWithImpl<$Res>
    implements $WorkoutMemoConfigCopyWith<$Res> {
  _$WorkoutMemoConfigCopyWithImpl(this._self, this._then);

  final WorkoutMemoConfig _self;
  final $Res Function(WorkoutMemoConfig) _then;

/// Create a copy of WorkoutMemoConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? feels = null,Object? promptWindowMinutes = null,Object? noteMaxLength = null,}) {
  return _then(_self.copyWith(
feels: null == feels ? _self.feels : feels // ignore: cast_nullable_to_non_nullable
as List<MemoFeel>,promptWindowMinutes: null == promptWindowMinutes ? _self.promptWindowMinutes : promptWindowMinutes // ignore: cast_nullable_to_non_nullable
as int,noteMaxLength: null == noteMaxLength ? _self.noteMaxLength : noteMaxLength // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutMemoConfig].
extension WorkoutMemoConfigPatterns on WorkoutMemoConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutMemoConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutMemoConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutMemoConfig value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutMemoConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutMemoConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutMemoConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MemoFeel> feels,  int promptWindowMinutes,  int noteMaxLength)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutMemoConfig() when $default != null:
return $default(_that.feels,_that.promptWindowMinutes,_that.noteMaxLength);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MemoFeel> feels,  int promptWindowMinutes,  int noteMaxLength)  $default,) {final _that = this;
switch (_that) {
case _WorkoutMemoConfig():
return $default(_that.feels,_that.promptWindowMinutes,_that.noteMaxLength);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MemoFeel> feels,  int promptWindowMinutes,  int noteMaxLength)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutMemoConfig() when $default != null:
return $default(_that.feels,_that.promptWindowMinutes,_that.noteMaxLength);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutMemoConfig extends WorkoutMemoConfig {
  const _WorkoutMemoConfig({final  List<MemoFeel> feels = const [MemoFeel(key: 'easy', label: '轻松', emoji: '😌'), MemoFeel(key: 'ok', label: '刚好', emoji: '🙂'), MemoFeel(key: 'hard', label: '吃力', emoji: '😮‍💨')], this.promptWindowMinutes = 30, this.noteMaxLength = 100}): _feels = feels,super._();
  

 final  List<MemoFeel> _feels;
@override@JsonKey() List<MemoFeel> get feels {
  if (_feels is EqualUnmodifiableListView) return _feels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_feels);
}

/// 完成后多久之内今日面板还问「刚才这张」。
@override@JsonKey() final  int promptWindowMinutes;
/// 一句话的长度上限(服务端硬上限是 500)。
@override@JsonKey() final  int noteMaxLength;

/// Create a copy of WorkoutMemoConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutMemoConfigCopyWith<_WorkoutMemoConfig> get copyWith => __$WorkoutMemoConfigCopyWithImpl<_WorkoutMemoConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutMemoConfig&&const DeepCollectionEquality().equals(other._feels, _feels)&&(identical(other.promptWindowMinutes, promptWindowMinutes) || other.promptWindowMinutes == promptWindowMinutes)&&(identical(other.noteMaxLength, noteMaxLength) || other.noteMaxLength == noteMaxLength));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_feels),promptWindowMinutes,noteMaxLength);

@override
String toString() {
  return 'WorkoutMemoConfig(feels: $feels, promptWindowMinutes: $promptWindowMinutes, noteMaxLength: $noteMaxLength)';
}


}

/// @nodoc
abstract mixin class _$WorkoutMemoConfigCopyWith<$Res> implements $WorkoutMemoConfigCopyWith<$Res> {
  factory _$WorkoutMemoConfigCopyWith(_WorkoutMemoConfig value, $Res Function(_WorkoutMemoConfig) _then) = __$WorkoutMemoConfigCopyWithImpl;
@override @useResult
$Res call({
 List<MemoFeel> feels, int promptWindowMinutes, int noteMaxLength
});




}
/// @nodoc
class __$WorkoutMemoConfigCopyWithImpl<$Res>
    implements _$WorkoutMemoConfigCopyWith<$Res> {
  __$WorkoutMemoConfigCopyWithImpl(this._self, this._then);

  final _WorkoutMemoConfig _self;
  final $Res Function(_WorkoutMemoConfig) _then;

/// Create a copy of WorkoutMemoConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? feels = null,Object? promptWindowMinutes = null,Object? noteMaxLength = null,}) {
  return _then(_WorkoutMemoConfig(
feels: null == feels ? _self._feels : feels // ignore: cast_nullable_to_non_nullable
as List<MemoFeel>,promptWindowMinutes: null == promptWindowMinutes ? _self.promptWindowMinutes : promptWindowMinutes // ignore: cast_nullable_to_non_nullable
as int,noteMaxLength: null == noteMaxLength ? _self.noteMaxLength : noteMaxLength // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
