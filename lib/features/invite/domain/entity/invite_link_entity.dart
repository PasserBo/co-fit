// DRAFT MODEL: UI 改造期间预估的数据模型,尚未与后端确认
// 邀请链接解析结果。格式定义见 ../invite_link_format.dart。
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_link_entity.freezed.dart';

@freezed
abstract class InviteLinkEntity with _$InviteLinkEntity {
  const factory InviteLinkEntity({
    required String roomId,
    required String hash,
  }) = _InviteLinkEntity;
}
