// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_info_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomInfoEntity {

 String get roomId; String get name; String get description; String get visibility; String get ownerId; String get shareLinkHash; String get shareSalt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of RoomInfoEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomInfoEntityCopyWith<RoomInfoEntity> get copyWith => _$RoomInfoEntityCopyWithImpl<RoomInfoEntity>(this as RoomInfoEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomInfoEntity&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.shareLinkHash, shareLinkHash) || other.shareLinkHash == shareLinkHash)&&(identical(other.shareSalt, shareSalt) || other.shareSalt == shareSalt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,name,description,visibility,ownerId,shareLinkHash,shareSalt,createdAt,updatedAt);

@override
String toString() {
  return 'RoomInfoEntity(roomId: $roomId, name: $name, description: $description, visibility: $visibility, ownerId: $ownerId, shareLinkHash: $shareLinkHash, shareSalt: $shareSalt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RoomInfoEntityCopyWith<$Res>  {
  factory $RoomInfoEntityCopyWith(RoomInfoEntity value, $Res Function(RoomInfoEntity) _then) = _$RoomInfoEntityCopyWithImpl;
@useResult
$Res call({
 String roomId, String name, String description, String visibility, String ownerId, String shareLinkHash, String shareSalt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$RoomInfoEntityCopyWithImpl<$Res>
    implements $RoomInfoEntityCopyWith<$Res> {
  _$RoomInfoEntityCopyWithImpl(this._self, this._then);

  final RoomInfoEntity _self;
  final $Res Function(RoomInfoEntity) _then;

/// Create a copy of RoomInfoEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? name = null,Object? description = null,Object? visibility = null,Object? ownerId = null,Object? shareLinkHash = null,Object? shareSalt = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shareLinkHash: null == shareLinkHash ? _self.shareLinkHash : shareLinkHash // ignore: cast_nullable_to_non_nullable
as String,shareSalt: null == shareSalt ? _self.shareSalt : shareSalt // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomInfoEntity].
extension RoomInfoEntityPatterns on RoomInfoEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomInfoEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomInfoEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomInfoEntity value)  $default,){
final _that = this;
switch (_that) {
case _RoomInfoEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomInfoEntity value)?  $default,){
final _that = this;
switch (_that) {
case _RoomInfoEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String name,  String description,  String visibility,  String ownerId,  String shareLinkHash,  String shareSalt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomInfoEntity() when $default != null:
return $default(_that.roomId,_that.name,_that.description,_that.visibility,_that.ownerId,_that.shareLinkHash,_that.shareSalt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String name,  String description,  String visibility,  String ownerId,  String shareLinkHash,  String shareSalt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RoomInfoEntity():
return $default(_that.roomId,_that.name,_that.description,_that.visibility,_that.ownerId,_that.shareLinkHash,_that.shareSalt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String name,  String description,  String visibility,  String ownerId,  String shareLinkHash,  String shareSalt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoomInfoEntity() when $default != null:
return $default(_that.roomId,_that.name,_that.description,_that.visibility,_that.ownerId,_that.shareLinkHash,_that.shareSalt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RoomInfoEntity implements RoomInfoEntity {
  const _RoomInfoEntity({required this.roomId, required this.name, required this.description, required this.visibility, required this.ownerId, required this.shareLinkHash, required this.shareSalt, this.createdAt, this.updatedAt});
  

@override final  String roomId;
@override final  String name;
@override final  String description;
@override final  String visibility;
@override final  String ownerId;
@override final  String shareLinkHash;
@override final  String shareSalt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of RoomInfoEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomInfoEntityCopyWith<_RoomInfoEntity> get copyWith => __$RoomInfoEntityCopyWithImpl<_RoomInfoEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomInfoEntity&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.shareLinkHash, shareLinkHash) || other.shareLinkHash == shareLinkHash)&&(identical(other.shareSalt, shareSalt) || other.shareSalt == shareSalt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,roomId,name,description,visibility,ownerId,shareLinkHash,shareSalt,createdAt,updatedAt);

@override
String toString() {
  return 'RoomInfoEntity(roomId: $roomId, name: $name, description: $description, visibility: $visibility, ownerId: $ownerId, shareLinkHash: $shareLinkHash, shareSalt: $shareSalt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RoomInfoEntityCopyWith<$Res> implements $RoomInfoEntityCopyWith<$Res> {
  factory _$RoomInfoEntityCopyWith(_RoomInfoEntity value, $Res Function(_RoomInfoEntity) _then) = __$RoomInfoEntityCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String name, String description, String visibility, String ownerId, String shareLinkHash, String shareSalt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$RoomInfoEntityCopyWithImpl<$Res>
    implements _$RoomInfoEntityCopyWith<$Res> {
  __$RoomInfoEntityCopyWithImpl(this._self, this._then);

  final _RoomInfoEntity _self;
  final $Res Function(_RoomInfoEntity) _then;

/// Create a copy of RoomInfoEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? name = null,Object? description = null,Object? visibility = null,Object? ownerId = null,Object? shareLinkHash = null,Object? shareSalt = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RoomInfoEntity(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,shareLinkHash: null == shareLinkHash ? _self.shareLinkHash : shareLinkHash // ignore: cast_nullable_to_non_nullable
as String,shareSalt: null == shareSalt ? _self.shareSalt : shareSalt // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
