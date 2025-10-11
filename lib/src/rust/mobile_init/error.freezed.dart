// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Error {

 Error get field0;
/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorCopyWith<Error> get copyWith => _$ErrorCopyWithImpl<Error>(this as Error, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Error&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Error(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ErrorCopyWith<$Res>  {
  factory $ErrorCopyWith(Error value, $Res Function(Error) _then) = _$ErrorCopyWithImpl;
@useResult
$Res call({
 Error field0
});


$ErrorCopyWith<$Res> get field0;

}
/// @nodoc
class _$ErrorCopyWithImpl<$Res>
    implements $ErrorCopyWith<$Res> {
  _$ErrorCopyWithImpl(this._self, this._then);

  final Error _self;
  final $Res Function(Error) _then;

/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field0 = null,}) {
  return _then(_self.copyWith(
field0: null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Error,
  ));
}
/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorCopyWith<$Res> get field0 {
  
  return $ErrorCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}


/// Adds pattern-matching-related methods to [Error].
extension ErrorPatterns on Error {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Error_Btleplug value)?  btleplug,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Error_Btleplug() when btleplug != null:
return btleplug(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Error_Btleplug value)  btleplug,}){
final _that = this;
switch (_that) {
case Error_Btleplug():
return btleplug(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Error_Btleplug value)?  btleplug,}){
final _that = this;
switch (_that) {
case Error_Btleplug() when btleplug != null:
return btleplug(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Error field0)?  btleplug,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Error_Btleplug() when btleplug != null:
return btleplug(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Error field0)  btleplug,}) {final _that = this;
switch (_that) {
case Error_Btleplug():
return btleplug(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Error field0)?  btleplug,}) {final _that = this;
switch (_that) {
case Error_Btleplug() when btleplug != null:
return btleplug(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class Error_Btleplug extends Error {
  const Error_Btleplug(this.field0): super._();
  

@override final  Error field0;

/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Error_BtleplugCopyWith<Error_Btleplug> get copyWith => _$Error_BtleplugCopyWithImpl<Error_Btleplug>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Error_Btleplug&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Error.btleplug(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Error_BtleplugCopyWith<$Res> implements $ErrorCopyWith<$Res> {
  factory $Error_BtleplugCopyWith(Error_Btleplug value, $Res Function(Error_Btleplug) _then) = _$Error_BtleplugCopyWithImpl;
@override @useResult
$Res call({
 Error field0
});


@override $ErrorCopyWith<$Res> get field0;

}
/// @nodoc
class _$Error_BtleplugCopyWithImpl<$Res>
    implements $Error_BtleplugCopyWith<$Res> {
  _$Error_BtleplugCopyWithImpl(this._self, this._then);

  final Error_Btleplug _self;
  final $Res Function(Error_Btleplug) _then;

/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Error_Btleplug(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Error,
  ));
}

/// Create a copy of Error
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorCopyWith<$Res> get field0 {
  
  return $ErrorCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

// dart format on
