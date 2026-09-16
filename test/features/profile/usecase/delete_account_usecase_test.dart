import 'package:cofit/features/auth/domain/repository/auth_repository.dart';
import 'package:cofit/features/profile/data/firebase_user_data_eraser.dart';
import 'package:cofit/features/profile/usecase/delete_account_usecase.dart';
import 'package:cofit/features/room/data/firebase_room_repository.dart';
import 'package:cofit/features/room/domain/entity/room_info_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录调用顺序 —— 清理必须发生在注销 Auth 用户之前,否则 uid 失效后
/// rules 会拒绝一切写入,用户数据将永久残留。
final _calls = <String>[];

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.appleCode, this.reauthError});

  final String? appleCode;
  final Object? reauthError;
  String? receivedAppleCode;

  @override
  Future<String?> reauthenticate() async {
    _calls.add('reauthenticate');
    if (reauthError != null) {
      throw reauthError!;
    }
    return appleCode;
  }

  @override
  Future<void> deleteAccount({String? appleAuthorizationCode}) async {
    _calls.add('deleteAccount');
    receivedAppleCode = appleAuthorizationCode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeRoomRepository implements FirebaseRoomRepository {
  _FakeRoomRepository(this.rooms);

  /// roomId → ownerId
  final Map<String, String> rooms;
  final dissolved = <String>[];
  final left = <String>[];

  @override
  Future<List<String>> fetchJoinedRoomIds({required String userId}) async {
    _calls.add('fetchJoinedRoomIds');
    return rooms.keys.toList();
  }

  @override
  Future<RoomInfoEntity?> fetchRoomInfo({required String roomId}) async {
    final ownerId = rooms[roomId];
    if (ownerId == null) {
      return null;
    }
    return RoomInfoEntity(
      roomId: roomId,
      name: roomId,
      description: '',
      visibility: RoomVisibility.unlisted,
      ownerId: ownerId,
      shareLinkHash: 'h',
      shareSalt: 's',
    );
  }

  @override
  Future<void> dissolveRoom({
    required String roomId,
    required String ownerId,
  }) async {
    _calls.add('dissolve:$roomId');
    dissolved.add(roomId);
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    _calls.add('leave:$roomId');
    left.add(roomId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeEraser implements FirebaseUserDataEraser {
  bool erased = false;
  Object? throwOnErase;

  @override
  Future<void> eraseUserData({required String userId}) async {
    _calls.add('eraseUserData');
    if (throwOnErase != null) {
      throw throwOnErase!;
    }
    erased = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  setUp(_calls.clear);

  test('清理顺序:重认证 → 房间 → 数据 → 注销账号', () async {
    final auth = _FakeAuthRepository();
    final rooms = _FakeRoomRepository({'r1': 'other'});
    final eraser = _FakeEraser();

    await DeleteAccountUsecase(
      authRepository: auth,
      roomRepository: rooms,
      userDataEraser: eraser,
    ).execute(userId: 'me');

    expect(_calls.first, 'reauthenticate');
    expect(_calls.indexOf('eraseUserData'), lessThan(_calls.indexOf('deleteAccount')));
    expect(_calls.last, 'deleteAccount');
  });

  test('房主房间解散,他人房间退出', () async {
    final rooms = _FakeRoomRepository({'mine': 'me', 'theirs': 'other'});
    final eraser = _FakeEraser();

    await DeleteAccountUsecase(
      authRepository: _FakeAuthRepository(),
      roomRepository: rooms,
      userDataEraser: eraser,
    ).execute(userId: 'me');

    expect(rooms.dissolved, ['mine']);
    expect(rooms.left, ['theirs']);
    expect(eraser.erased, isTrue);
  });

  test('Apple 授权码透传给 deleteAccount(用于撤销 token)', () async {
    final auth = _FakeAuthRepository(appleCode: 'code-123');

    await DeleteAccountUsecase(
      authRepository: auth,
      roomRepository: _FakeRoomRepository({}),
      userDataEraser: _FakeEraser(),
    ).execute(userId: 'me');

    expect(auth.receivedAppleCode, 'code-123');
  });

  test('重认证失败则完全不动数据', () async {
    final rooms = _FakeRoomRepository({'r1': 'me'});
    final eraser = _FakeEraser();

    await expectLater(
      DeleteAccountUsecase(
        authRepository: _FakeAuthRepository(
          reauthError: FirebaseAuthException(code: 'requires-recent-login'),
        ),
        roomRepository: rooms,
        userDataEraser: eraser,
      ).execute(userId: 'me'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(rooms.dissolved, isEmpty);
    expect(eraser.erased, isFalse);
    expect(_calls, ['reauthenticate']);
  });

  test('单个房间清理失败不阻断整体删除', () async {
    final rooms = _FakeRoomRepository({'broken': 'me'})..rooms.clear();
    rooms.rooms['broken'] = 'me';
    final eraser = _FakeEraser();

    await DeleteAccountUsecase(
      authRepository: _FakeAuthRepository(),
      roomRepository: rooms,
      userDataEraser: eraser,
    ).execute(userId: 'me');

    expect(eraser.erased, isTrue, reason: '房间处理不应阻断数据清理');
    expect(_calls.last, 'deleteAccount');
  });
}
