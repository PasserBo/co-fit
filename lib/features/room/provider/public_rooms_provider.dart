import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository_provider.dart';
import '../domain/entity/room_info_entity.dart';
import '../usecase/fetch_public_rooms_usecase.dart';

final fetchPublicRoomsUsecaseProvider = Provider<FetchPublicRoomsUsecase>((
  ref,
) {
  return FetchPublicRoomsUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

/// 发现房间页的公开房间列表(已排序)。离开页面即释放,下次进入重新拉取;
/// 下拉刷新 = `ref.refresh(publicRoomsProvider.future)`。
/// 关闭 Riverpod 3 的自动重试:离线时立即进入失败态,由页面上的「重试」驱动。
final publicRoomsProvider = FutureProvider.autoDispose<List<RoomInfoEntity>>(
  (ref) => ref.watch(fetchPublicRoomsUsecaseProvider).execute(),
  retry: (_, _) => null,
);
