// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_link_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteLinkEntity {

 String get roomId; String get hash;
/// Create a copy of InviteLinkEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteLinkEntityCopyWith<InviteLinkEntity> get copyWith => _$InviteLinkEntityCopyWithImpl<InviteLinkEntity>(this as InviteLinkEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteLinkEntity&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hash, hash) || other.hash == hash));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,hash);

@override
String toString() {
  return 'InviteLinkEntity(roomId: $roomId, hash: $hash)';
}


}

/// @nodoc
abstract mixin class $InviteLinkEntityCopyWith<$Res>  {
  factory $InviteLinkEntityCopyWith(InviteLinkEntity value, $Res Function(InviteLinkEntity) _then) = _$InviteLinkEntityCopyWithImpl;
@useResult
$Res call({
 String roomId, String hash
});




}
/// @nodoc
class _$InviteLinkEntityCopyWithImpl<$Res>
    implements $InviteLinkEntityCopyWith<$Res> {
  _$InviteLinkEntityCopyWithImpl(this._self, this._then);

  final InviteLinkEntity _self;
  final $Res Function(InviteLinkEntity) _then;

/// Create a copy of InviteLinkEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? hash = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteLinkEntity].
extension InviteLinkEntityPatterns on InviteLinkEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteLinkEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteLinkEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteLinkEntity value)  $default,){
final _that = this;
switch (_that) {
case _InviteLinkEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteLinkEntity value)?  $default,){
final _that = this;
switch (_that) {
case _InviteLinkEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String hash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteLinkEntity() when $default != null:
return $default(_that.roomId,_that.hash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String hash)  $default,) {final _that = this;
switch (_that) {
case _InviteLinkEntity():
return $default(_that.roomId,_that.hash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String hash)?  $default,) {final _that = this;
switch (_that) {
case _InviteLinkEntity() when $default != null:
return $default(_that.roomId,_that.hash);case _:
  return null;

}
}

}

/// @nodoc


class _InviteLinkEntity implements InviteLinkEntity {
  const _InviteLinkEntity({required this.roomId, required this.hash});
  

@override final  String roomId;
@override final  String hash;

/// Create a copy of InviteLinkEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteLinkEntityCopyWith<_InviteLinkEntity> get copyWith => __$InviteLinkEntityCopyWithImpl<_InviteLinkEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteLinkEntity&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hash, hash) || other.hash == hash));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,hash);

@override
String toString() {
  return 'InviteLinkEntity(roomId: $roomId, hash: $hash)';
}


}

/// @nodoc
abstract mixin class _$InviteLinkEntityCopyWith<$Res> implements $InviteLinkEntityCopyWith<$Res> {
  factory _$InviteLinkEntityCopyWith(_InviteLinkEntity value, $Res Function(_InviteLinkEntity) _then) = __$InviteLinkEntityCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String hash
});




}
/// @nodoc
class __$InviteLinkEntityCopyWithImpl<$Res>
    implements _$InviteLinkEntityCopyWith<$Res> {
  __$InviteLinkEntityCopyWithImpl(this._self, this._then);

  final _InviteLinkEntity _self;
  final $Res Function(_InviteLinkEntity) _then;

/// Create a copy of InviteLinkEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? hash = null,}) {
  return _then(_InviteLinkEntity(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
