// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_deck.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActionDeck {

 String get id; String get name;/// 引用 card_templates 文档 id。有序(= 扇形手牌展开顺序、拖动排序结果),允许重复。
 List<String> get cardIds;
/// Create a copy of ActionDeck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionDeckCopyWith<ActionDeck> get copyWith => _$ActionDeckCopyWithImpl<ActionDeck>(this as ActionDeck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionDeck&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.cardIds, cardIds));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(cardIds));

@override
String toString() {
  return 'ActionDeck(id: $id, name: $name, cardIds: $cardIds)';
}


}

/// @nodoc
abstract mixin class $ActionDeckCopyWith<$Res>  {
  factory $ActionDeckCopyWith(ActionDeck value, $Res Function(ActionDeck) _then) = _$ActionDeckCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> cardIds
});




}
/// @nodoc
class _$ActionDeckCopyWithImpl<$Res>
    implements $ActionDeckCopyWith<$Res> {
  _$ActionDeckCopyWithImpl(this._self, this._then);

  final ActionDeck _self;
  final $Res Function(ActionDeck) _then;

/// Create a copy of ActionDeck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? cardIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cardIds: null == cardIds ? _self.cardIds : cardIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionDeck].
extension ActionDeckPatterns on ActionDeck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionDeck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionDeck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionDeck value)  $default,){
final _that = this;
switch (_that) {
case _ActionDeck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionDeck value)?  $default,){
final _that = this;
switch (_that) {
case _ActionDeck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> cardIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionDeck() when $default != null:
return $default(_that.id,_that.name,_that.cardIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> cardIds)  $default,) {final _that = this;
switch (_that) {
case _ActionDeck():
return $default(_that.id,_that.name,_that.cardIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> cardIds)?  $default,) {final _that = this;
switch (_that) {
case _ActionDeck() when $default != null:
return $default(_that.id,_that.name,_that.cardIds);case _:
  return null;

}
}

}

/// @nodoc


class _ActionDeck implements ActionDeck {
  const _ActionDeck({required this.id, required this.name, required final  List<String> cardIds}): _cardIds = cardIds;
  

@override final  String id;
@override final  String name;
/// 引用 card_templates 文档 id。有序(= 扇形手牌展开顺序、拖动排序结果),允许重复。
 final  List<String> _cardIds;
/// 引用 card_templates 文档 id。有序(= 扇形手牌展开顺序、拖动排序结果),允许重复。
@override List<String> get cardIds {
  if (_cardIds is EqualUnmodifiableListView) return _cardIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cardIds);
}


/// Create a copy of ActionDeck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionDeckCopyWith<_ActionDeck> get copyWith => __$ActionDeckCopyWithImpl<_ActionDeck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionDeck&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._cardIds, _cardIds));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_cardIds));

@override
String toString() {
  return 'ActionDeck(id: $id, name: $name, cardIds: $cardIds)';
}


}

/// @nodoc
abstract mixin class _$ActionDeckCopyWith<$Res> implements $ActionDeckCopyWith<$Res> {
  factory _$ActionDeckCopyWith(_ActionDeck value, $Res Function(_ActionDeck) _then) = __$ActionDeckCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> cardIds
});




}
/// @nodoc
class __$ActionDeckCopyWithImpl<$Res>
    implements _$ActionDeckCopyWith<$Res> {
  __$ActionDeckCopyWithImpl(this._self, this._then);

  final _ActionDeck _self;
  final $Res Function(_ActionDeck) _then;

/// Create a copy of ActionDeck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? cardIds = null,}) {
  return _then(_ActionDeck(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cardIds: null == cardIds ? _self._cardIds : cardIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
