// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_presence_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomPresenceMember {

 String get clientId; String get userId; UserActivityStatusEntity get activityStatus;
/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomPresenceMemberCopyWith<RoomPresenceMember> get copyWith => _$RoomPresenceMemberCopyWithImpl<RoomPresenceMember>(this as RoomPresenceMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomPresenceMember&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.activityStatus, activityStatus) || other.activityStatus == activityStatus));
}


@override
int get hashCode => Object.hash(runtimeType,clientId,userId,activityStatus);

@override
String toString() {
  return 'RoomPresenceMember(clientId: $clientId, userId: $userId, activityStatus: $activityStatus)';
}


}

/// @nodoc
abstract mixin class $RoomPresenceMemberCopyWith<$Res>  {
  factory $RoomPresenceMemberCopyWith(RoomPresenceMember value, $Res Function(RoomPresenceMember) _then) = _$RoomPresenceMemberCopyWithImpl;
@useResult
$Res call({
 String clientId, String userId, UserActivityStatusEntity activityStatus
});


$UserActivityStatusEntityCopyWith<$Res> get activityStatus;

}
/// @nodoc
class _$RoomPresenceMemberCopyWithImpl<$Res>
    implements $RoomPresenceMemberCopyWith<$Res> {
  _$RoomPresenceMemberCopyWithImpl(this._self, this._then);

  final RoomPresenceMember _self;
  final $Res Function(RoomPresenceMember) _then;

/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? userId = null,Object? activityStatus = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,activityStatus: null == activityStatus ? _self.activityStatus : activityStatus // ignore: cast_nullable_to_non_nullable
as UserActivityStatusEntity,
  ));
}
/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserActivityStatusEntityCopyWith<$Res> get activityStatus {
  
  return $UserActivityStatusEntityCopyWith<$Res>(_self.activityStatus, (value) {
    return _then(_self.copyWith(activityStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [RoomPresenceMember].
extension RoomPresenceMemberPatterns on RoomPresenceMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomPresenceMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomPresenceMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomPresenceMember value)  $default,){
final _that = this;
switch (_that) {
case _RoomPresenceMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomPresenceMember value)?  $default,){
final _that = this;
switch (_that) {
case _RoomPresenceMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String userId,  UserActivityStatusEntity activityStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomPresenceMember() when $default != null:
return $default(_that.clientId,_that.userId,_that.activityStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String userId,  UserActivityStatusEntity activityStatus)  $default,) {final _that = this;
switch (_that) {
case _RoomPresenceMember():
return $default(_that.clientId,_that.userId,_that.activityStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String userId,  UserActivityStatusEntity activityStatus)?  $default,) {final _that = this;
switch (_that) {
case _RoomPresenceMember() when $default != null:
return $default(_that.clientId,_that.userId,_that.activityStatus);case _:
  return null;

}
}

}

/// @nodoc


class _RoomPresenceMember implements RoomPresenceMember {
  const _RoomPresenceMember({required this.clientId, required this.userId, this.activityStatus = const UserActivityStatusEntity(activityState: UserActivityState.idle)});
  

@override final  String clientId;
@override final  String userId;
@override@JsonKey() final  UserActivityStatusEntity activityStatus;

/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomPresenceMemberCopyWith<_RoomPresenceMember> get copyWith => __$RoomPresenceMemberCopyWithImpl<_RoomPresenceMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomPresenceMember&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.activityStatus, activityStatus) || other.activityStatus == activityStatus));
}


@override
int get hashCode => Object.hash(runtimeType,clientId,userId,activityStatus);

@override
String toString() {
  return 'RoomPresenceMember(clientId: $clientId, userId: $userId, activityStatus: $activityStatus)';
}


}

/// @nodoc
abstract mixin class _$RoomPresenceMemberCopyWith<$Res> implements $RoomPresenceMemberCopyWith<$Res> {
  factory _$RoomPresenceMemberCopyWith(_RoomPresenceMember value, $Res Function(_RoomPresenceMember) _then) = __$RoomPresenceMemberCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String userId, UserActivityStatusEntity activityStatus
});


@override $UserActivityStatusEntityCopyWith<$Res> get activityStatus;

}
/// @nodoc
class __$RoomPresenceMemberCopyWithImpl<$Res>
    implements _$RoomPresenceMemberCopyWith<$Res> {
  __$RoomPresenceMemberCopyWithImpl(this._self, this._then);

  final _RoomPresenceMember _self;
  final $Res Function(_RoomPresenceMember) _then;

/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? userId = null,Object? activityStatus = null,}) {
  return _then(_RoomPresenceMember(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,activityStatus: null == activityStatus ? _self.activityStatus : activityStatus // ignore: cast_nullable_to_non_nullable
as UserActivityStatusEntity,
  ));
}

/// Create a copy of RoomPresenceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserActivityStatusEntityCopyWith<$Res> get activityStatus {
  
  return $UserActivityStatusEntityCopyWith<$Res>(_self.activityStatus, (value) {
    return _then(_self.copyWith(activityStatus: value));
  });
}
}

// dart format on
