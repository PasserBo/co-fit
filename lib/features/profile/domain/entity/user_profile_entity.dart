// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认
// Firestore 文档: users/{uid}
// avatarConfig 为形象占位配置,等 avatar 特性定稿后替换具体字段。
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_entity.freezed.dart';

@freezed
abstract class UserProfileEntity with _$UserProfileEntity {
  const UserProfileEntity._();

  const factory UserProfileEntity({
    required String uid,
    required String nickname,
    @Default(<String, dynamic>{'presetId': 'default'})
    Map<String, dynamic> avatarConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfileEntity;

  static const int nicknameMaxLength = 20;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'avatarConfig': avatarConfig,
    };
  }

  factory UserProfileEntity.fromMap(Map<String, dynamic> source) {
    final rawAvatarConfig = source['avatarConfig'];
    return UserProfileEntity(
      uid: (source['uid'] ?? '').toString(),
      nickname: (source['nickname'] ?? '').toString(),
      avatarConfig: rawAvatarConfig is Map
          ? Map<String, dynamic>.from(rawAvatarConfig)
          : const <String, dynamic>{'presetId': 'default'},
      createdAt: _asDateTime(source['createdAt']),
      updatedAt: _asDateTime(source['updatedAt']),
    );
  }

  static DateTime? _asDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    final dynamic maybeDate = (value as dynamic).toDate?.call();
    if (maybeDate is DateTime) {
      return maybeDate.toLocal();
    }
    return null;
  }
}
