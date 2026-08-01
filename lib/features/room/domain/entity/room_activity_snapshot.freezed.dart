// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_activity_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomActivitySnapshot {

 String get roomId; Map<String, ActionSession> get sessionsByUser;
/// Create a copy of RoomActivitySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomActivitySnapshotCopyWith<RoomActivitySnapshot> get copyWith => _$RoomActivitySnapshotCopyWithImpl<RoomActivitySnapshot>(this as RoomActivitySnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomActivitySnapshot&&(identical(other.roomId, roomId) || other.roomId == roomId)&&const DeepCollectionEquality().equals(other.sessionsByUser, sessionsByUser));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,const DeepCollectionEquality().hash(sessionsByUser));

@override
String toString() {
  return 'RoomActivitySnapshot(roomId: $roomId, sessionsByUser: $sessionsByUser)';
}


}

/// @nodoc
abstract mixin class $RoomActivitySnapshotCopyWith<$Res>  {
  factory $RoomActivitySnapshotCopyWith(RoomActivitySnapshot value, $Res Function(RoomActivitySnapshot) _then) = _$RoomActivitySnapshotCopyWithImpl;
@useResult
$Res call({
 String roomId, Map<String, ActionSession> sessionsByUser
});




}
/// @nodoc
class _$RoomActivitySnapshotCopyWithImpl<$Res>
    implements $RoomActivitySnapshotCopyWith<$Res> {
  _$RoomActivitySnapshotCopyWithImpl(this._self, this._then);

  final RoomActivitySnapshot _self;
  final $Res Function(RoomActivitySnapshot) _then;

/// Create a copy of RoomActivitySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? sessionsByUser = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,sessionsByUser: null == sessionsByUser ? _self.sessionsByUser : sessionsByUser // ignore: cast_nullable_to_non_nullable
as Map<String, ActionSession>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomActivitySnapshot].
extension RoomActivitySnapshotPatterns on RoomActivitySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomActivitySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomActivitySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomActivitySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _RoomActivitySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomActivitySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _RoomActivitySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  Map<String, ActionSession> sessionsByUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomActivitySnapshot() when $default != null:
return $default(_that.roomId,_that.sessionsByUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  Map<String, ActionSession> sessionsByUser)  $default,) {final _that = this;
switch (_that) {
case _RoomActivitySnapshot():
return $default(_that.roomId,_that.sessionsByUser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  Map<String, ActionSession> sessionsByUser)?  $default,) {final _that = this;
switch (_that) {
case _RoomActivitySnapshot() when $default != null:
return $default(_that.roomId,_that.sessionsByUser);case _:
  return null;

}
}

}

/// @nodoc


class _RoomActivitySnapshot extends RoomActivitySnapshot {
  const _RoomActivitySnapshot({required this.roomId, final  Map<String, ActionSession> sessionsByUser = const <String, ActionSession>{}}): _sessionsByUser = sessionsByUser,super._();
  

@override final  String roomId;
 final  Map<String, ActionSession> _sessionsByUser;
@override@JsonKey() Map<String, ActionSession> get sessionsByUser {
  if (_sessionsByUser is EqualUnmodifiableMapView) return _sessionsByUser;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionsByUser);
}


/// Create a copy of RoomActivitySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomActivitySnapshotCopyWith<_RoomActivitySnapshot> get copyWith => __$RoomActivitySnapshotCopyWithImpl<_RoomActivitySnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomActivitySnapshot&&(identical(other.roomId, roomId) || other.roomId == roomId)&&const DeepCollectionEquality().equals(other._sessionsByUser, _sessionsByUser));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,const DeepCollectionEquality().hash(_sessionsByUser));

@override
String toString() {
  return 'RoomActivitySnapshot(roomId: $roomId, sessionsByUser: $sessionsByUser)';
}


}

/// @nodoc
abstract mixin class _$RoomActivitySnapshotCopyWith<$Res> implements $RoomActivitySnapshotCopyWith<$Res> {
  factory _$RoomActivitySnapshotCopyWith(_RoomActivitySnapshot value, $Res Function(_RoomActivitySnapshot) _then) = __$RoomActivitySnapshotCopyWithImpl;
@override @useResult
$Res call({
 String roomId, Map<String, ActionSession> sessionsByUser
});




}
/// @nodoc
class __$RoomActivitySnapshotCopyWithImpl<$Res>
    implements _$RoomActivitySnapshotCopyWith<$Res> {
  __$RoomActivitySnapshotCopyWithImpl(this._self, this._then);

  final _RoomActivitySnapshot _self;
  final $Res Function(_RoomActivitySnapshot) _then;

/// Create a copy of RoomActivitySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? sessionsByUser = null,}) {
  return _then(_RoomActivitySnapshot(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,sessionsByUser: null == sessionsByUser ? _self._sessionsByUser : sessionsByUser // ignore: cast_nullable_to_non_nullable
as Map<String, ActionSession>,
  ));
}


}

// dart format on
