import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/room_info_entity.dart';
import '../data/room_repository_provider.dart';
import '../usecase/create_room_usecase.dart';

class CreateRoomState {
  const CreateRoomState({
    required this.name,
    required this.description,
    required this.visibility,
    required this.isSubmitting,
    this.errorMessage,
    this.createdRoomId,
    this.createdShareLinkHash,
  });

  factory CreateRoomState.initial() {
    return const CreateRoomState(
      name: '',
      description: '',
      visibility: RoomVisibility.unlisted,
      isSubmitting: false,
    );
  }

  final String name;
  final String description;
  final String visibility;
  final bool isSubmitting;
  final String? errorMessage;
  final String? createdRoomId;
  final String? createdShareLinkHash;

  CreateRoomState copyWith({
    String? name,
    String? description,
    String? visibility,
    bool? isSubmitting,
    String? errorMessage,
    String? createdRoomId,
    String? createdShareLinkHash,
    bool clearErrorMessage = false,
    bool clearCreateResult = false,
  }) {
    return CreateRoomState(
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      createdRoomId: clearCreateResult
          ? null
          : (createdRoomId ?? this.createdRoomId),
      createdShareLinkHash: clearCreateResult
          ? null
          : (createdShareLinkHash ?? this.createdShareLinkHash),
    );
  }
}

class CreateRoomNotifier extends Notifier<CreateRoomState> {
  @override
  CreateRoomState build() {
    return CreateRoomState.initial();
  }

  void updateName(String value) {
    state = state.copyWith(
      name: value,
      clearErrorMessage: true,
      clearCreateResult: true,
    );
  }

  void updateDescription(String value) {
    state = state.copyWith(
      description: value,
      clearErrorMessage: true,
      clearCreateResult: true,
    );
  }

  void updateVisibility(String value) {
    if (!RoomVisibility.allowed.contains(value)) {
      return;
    }
    state = state.copyWith(
      visibility: value,
      clearErrorMessage: true,
      clearCreateResult: true,
    );
  }

  Future<void> submit({required String ownerId}) async {
    if (state.isSubmitting) {
      return;
    }
    state = state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
      clearCreateResult: true,
    );

    try {
      final usecase = ref.read(createRoomUsecaseProvider);
      final room = await usecase.execute(
        name: state.name,
        description: state.description,
        visibility: state.visibility,
        ownerId: ownerId,
      );
      state = state.copyWith(
        isSubmitting: false,
        createdRoomId: room.roomId,
        createdShareLinkHash: room.shareLinkHash,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _asErrorMessage(error),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  void clearCreateResult() {
    state = state.copyWith(clearCreateResult: true);
  }

  String _asErrorMessage(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }
}

final createRoomUsecaseProvider = Provider<CreateRoomUsecase>((ref) {
  return CreateRoomUsecase(ref.watch(firebaseRoomRepositoryProvider));
});

final createRoomProvider =
    NotifierProvider<CreateRoomNotifier, CreateRoomState>(
      CreateRoomNotifier.new,
    );
