import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../room/data/room_repository_provider.dart';
import '../usecase/build_invite_link_usecase.dart';
import '../usecase/resolve_invite_usecase.dart';

final resolveInviteUsecaseProvider = Provider<ResolveInviteUsecase>((ref) {
  return ResolveInviteUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final buildInviteLinkUsecaseProvider = Provider<BuildInviteLinkUsecase>((ref) {
  return BuildInviteLinkUsecase();
});
