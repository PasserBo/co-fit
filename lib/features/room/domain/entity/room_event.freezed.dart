// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomEventPayload {

 int get schemaVersion; String get actionKey; int get durationSec; int get remainingSec; String get sessionId; Map<String, dynamic> get customData;
/// Create a copy of RoomEventPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomEventPayloadCopyWith<RoomEventPayload> get copyWith => _$RoomEventPayloadCopyWithImpl<RoomEventPayload>(this as RoomEventPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomEventPayload&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other.customData, customData));
}


@override
int get hashCode => Object.hash(runtimeType,schemaVersion,actionKey,durationSec,remainingSec,sessionId,const DeepCollectionEquality().hash(customData));

@override
String toString() {
  return 'RoomEventPayload(schemaVersion: $schemaVersion, actionKey: $actionKey, durationSec: $durationSec, remainingSec: $remainingSec, sessionId: $sessionId, customData: $customData)';
}


}

/// @nodoc
abstract mixin class $RoomEventPayloadCopyWith<$Res>  {
  factory $RoomEventPayloadCopyWith(RoomEventPayload value, $Res Function(RoomEventPayload) _then) = _$RoomEventPayloadCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, String actionKey, int durationSec, int remainingSec, String sessionId, Map<String, dynamic> customData
});




}
/// @nodoc
class _$RoomEventPayloadCopyWithImpl<$Res>
    implements $RoomEventPayloadCopyWith<$Res> {
  _$RoomEventPayloadCopyWithImpl(this._self, this._then);

  final RoomEventPayload _self;
  final $Res Function(RoomEventPayload) _then;

/// Create a copy of RoomEventPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? actionKey = null,Object? durationSec = null,Object? remainingSec = null,Object? sessionId = null,Object? customData = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,remainingSec: null == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,customData: null == customData ? _self.customData : customData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomEventPayload].
extension RoomEventPayloadPatterns on RoomEventPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomEventPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomEventPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomEventPayload value)  $default,){
final _that = this;
switch (_that) {
case _RoomEventPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomEventPayload value)?  $default,){
final _that = this;
switch (_that) {
case _RoomEventPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  String actionKey,  int durationSec,  int remainingSec,  String sessionId,  Map<String, dynamic> customData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomEventPayload() when $default != null:
return $default(_that.schemaVersion,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.customData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  String actionKey,  int durationSec,  int remainingSec,  String sessionId,  Map<String, dynamic> customData)  $default,) {final _that = this;
switch (_that) {
case _RoomEventPayload():
return $default(_that.schemaVersion,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.customData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  String actionKey,  int durationSec,  int remainingSec,  String sessionId,  Map<String, dynamic> customData)?  $default,) {final _that = this;
switch (_that) {
case _RoomEventPayload() when $default != null:
return $default(_that.schemaVersion,_that.actionKey,_that.durationSec,_that.remainingSec,_that.sessionId,_that.customData);case _:
  return null;

}
}

}

/// @nodoc


class _RoomEventPayload implements RoomEventPayload {
  const _RoomEventPayload({required this.schemaVersion, required this.actionKey, required this.durationSec, required this.remainingSec, required this.sessionId, final  Map<String, dynamic> customData = const <String, dynamic>{}}): _customData = customData;
  

@override final  int schemaVersion;
@override final  String actionKey;
@override final  int durationSec;
@override final  int remainingSec;
@override final  String sessionId;
 final  Map<String, dynamic> _customData;
@override@JsonKey() Map<String, dynamic> get customData {
  if (_customData is EqualUnmodifiableMapView) return _customData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customData);
}


/// Create a copy of RoomEventPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomEventPayloadCopyWith<_RoomEventPayload> get copyWith => __$RoomEventPayloadCopyWithImpl<_RoomEventPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomEventPayload&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.actionKey, actionKey) || other.actionKey == actionKey)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._customData, _customData));
}


@override
int get hashCode => Object.hash(runtimeType,schemaVersion,actionKey,durationSec,remainingSec,sessionId,const DeepCollectionEquality().hash(_customData));

@override
String toString() {
  return 'RoomEventPayload(schemaVersion: $schemaVersion, actionKey: $actionKey, durationSec: $durationSec, remainingSec: $remainingSec, sessionId: $sessionId, customData: $customData)';
}


}

/// @nodoc
abstract mixin class _$RoomEventPayloadCopyWith<$Res> implements $RoomEventPayloadCopyWith<$Res> {
  factory _$RoomEventPayloadCopyWith(_RoomEventPayload value, $Res Function(_RoomEventPayload) _then) = __$RoomEventPayloadCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, String actionKey, int durationSec, int remainingSec, String sessionId, Map<String, dynamic> customData
});




}
/// @nodoc
class __$RoomEventPayloadCopyWithImpl<$Res>
    implements _$RoomEventPayloadCopyWith<$Res> {
  __$RoomEventPayloadCopyWithImpl(this._self, this._then);

  final _RoomEventPayload _self;
  final $Res Function(_RoomEventPayload) _then;

/// Create a copy of RoomEventPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? actionKey = null,Object? durationSec = null,Object? remainingSec = null,Object? sessionId = null,Object? customData = null,}) {
  return _then(_RoomEventPayload(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,actionKey: null == actionKey ? _self.actionKey : actionKey // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,remainingSec: null == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,customData: null == customData ? _self._customData : customData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$RoomEvent {

 String get eventId; String get roomId; String get userId; String get type; DateTime get timestamp; RoomEventPayload get payload;
/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomEventCopyWith<RoomEvent> get copyWith => _$RoomEventCopyWithImpl<RoomEvent>(this as RoomEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,roomId,userId,type,timestamp,payload);

@override
String toString() {
  return 'RoomEvent(eventId: $eventId, roomId: $roomId, userId: $userId, type: $type, timestamp: $timestamp, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $RoomEventCopyWith<$Res>  {
  factory $RoomEventCopyWith(RoomEvent value, $Res Function(RoomEvent) _then) = _$RoomEventCopyWithImpl;
@useResult
$Res call({
 String eventId, String roomId, String userId, String type, DateTime timestamp, RoomEventPayload payload
});


$RoomEventPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$RoomEventCopyWithImpl<$Res>
    implements $RoomEventCopyWith<$Res> {
  _$RoomEventCopyWithImpl(this._self, this._then);

  final RoomEvent _self;
  final $Res Function(RoomEvent) _then;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? roomId = null,Object? userId = null,Object? type = null,Object? timestamp = null,Object? payload = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as RoomEventPayload,
  ));
}
/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomEventPayloadCopyWith<$Res> get payload {
  
  return $RoomEventPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}


/// Adds pattern-matching-related methods to [RoomEvent].
extension RoomEventPatterns on RoomEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomEvent value)  $default,){
final _that = this;
switch (_that) {
case _RoomEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String roomId,  String userId,  String type,  DateTime timestamp,  RoomEventPayload payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
return $default(_that.eventId,_that.roomId,_that.userId,_that.type,_that.timestamp,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String roomId,  String userId,  String type,  DateTime timestamp,  RoomEventPayload payload)  $default,) {final _that = this;
switch (_that) {
case _RoomEvent():
return $default(_that.eventId,_that.roomId,_that.userId,_that.type,_that.timestamp,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String roomId,  String userId,  String type,  DateTime timestamp,  RoomEventPayload payload)?  $default,) {final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
return $default(_that.eventId,_that.roomId,_that.userId,_that.type,_that.timestamp,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class _RoomEvent implements RoomEvent {
  const _RoomEvent({required this.eventId, required this.roomId, required this.userId, required this.type, required this.timestamp, required this.payload});
  

@override final  String eventId;
@override final  String roomId;
@override final  String userId;
@override final  String type;
@override final  DateTime timestamp;
@override final  RoomEventPayload payload;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomEventCopyWith<_RoomEvent> get copyWith => __$RoomEventCopyWithImpl<_RoomEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,roomId,userId,type,timestamp,payload);

@override
String toString() {
  return 'RoomEvent(eventId: $eventId, roomId: $roomId, userId: $userId, type: $type, timestamp: $timestamp, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$RoomEventCopyWith<$Res> implements $RoomEventCopyWith<$Res> {
  factory _$RoomEventCopyWith(_RoomEvent value, $Res Function(_RoomEvent) _then) = __$RoomEventCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String roomId, String userId, String type, DateTime timestamp, RoomEventPayload payload
});


@override $RoomEventPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class __$RoomEventCopyWithImpl<$Res>
    implements _$RoomEventCopyWith<$Res> {
  __$RoomEventCopyWithImpl(this._self, this._then);

  final _RoomEvent _self;
  final $Res Function(_RoomEvent) _then;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? roomId = null,Object? userId = null,Object? type = null,Object? timestamp = null,Object? payload = null,}) {
  return _then(_RoomEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as RoomEventPayload,
  ));
}

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomEventPayloadCopyWith<$Res> get payload {
  
  return $RoomEventPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

// dart format on
