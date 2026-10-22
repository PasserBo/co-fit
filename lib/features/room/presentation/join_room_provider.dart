import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_report_repository.dart';
import '../data/room_repository_provider.dart';
import '../usecase/dissolve_room_usecase.dart';
import '../usecase/join_room_usecase.dart';
import '../usecase/leave_room_usecase.dart';
import '../usecase/remove_room_member_usecase.dart';
import '../usecase/submit_report_usecase.dart';
import '../usecase/update_room_info_usecase.dart';

final joinRoomUsecaseProvider = Provider<JoinRoomUsecase>((ref) {
  return JoinRoomUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final leaveRoomUsecaseProvider = Provider<LeaveRoomUsecase>((ref) {
  return LeaveRoomUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final updateRoomInfoUsecaseProvider = Provider<UpdateRoomInfoUsecase>((ref) {
  return UpdateRoomInfoUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final dissolveRoomUsecaseProvider = Provider<DissolveRoomUsecase>((ref) {
  return DissolveRoomUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final removeRoomMemberUsecaseProvider = Provider<RemoveRoomMemberUsecase>((
  ref,
) {
  return RemoveRoomMemberUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final firebaseReportRepositoryProvider = Provider<FirebaseReportRepository>((
  ref,
) {
  return FirebaseReportRepository();
});

final submitReportUsecaseProvider = Provider<SubmitReportUsecase>((ref) {
  return SubmitReportUsecase(ref.watch(firebaseReportRepositoryProvider));
});
