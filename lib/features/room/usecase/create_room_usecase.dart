import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../data/firebase_room_repository.dart';
import '../data/room_info_model.dart';

class CreateRoomUsecase {
  CreateRoomUsecase(this._repository, {Uuid? uuid, Random? random})
    : _uuid = uuid ?? const Uuid(),
      _random = random ?? Random.secure();

  final FirebaseRoomRepository _repository;
  final Uuid _uuid;
  final Random _random;

  Future<RoomInfoModel> execute({
    required String name,
    required String description,
    required String visibility,
    required String ownerId,
  }) async {
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    final normalizedVisibility = visibility.trim().toLowerCase();
    final trimmedOwnerId = ownerId.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Room name must not be empty.');
    }
    if (!RoomVisibility.allowed.contains(normalizedVisibility)) {
      throw ArgumentError.value(
        visibility,
        'visibility',
        'Visibility must be one of: ${RoomVisibility.allowed.join(', ')}.',
      );
    }
    if (trimmedOwnerId.isEmpty) {
      throw ArgumentError.value(
        ownerId,
        'ownerId',
        'Owner id must not be empty.',
      );
    }

    final roomId = _uuid.v4();
    final shareSalt = _generateRandomSalt();
    final shareLinkHash = _buildShareLinkHash(
      roomId: roomId,
      ownerId: trimmedOwnerId,
      shareSalt: shareSalt,
    );
    final room = RoomInfoModel(
      roomId: roomId,
      name: trimmedName,
      description: trimmedDescription,
      visibility: normalizedVisibility,
      ownerId: trimmedOwnerId,
      shareLinkHash: shareLinkHash,
      shareSalt: shareSalt,
    );

    return _repository.createRoom(room: room);
  }

  String _generateRandomSalt() {
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _buildShareLinkHash({
    required String roomId,
    required String ownerId,
    required String shareSalt,
  }) {
    final payload = '$roomId:$ownerId:$shareSalt';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
