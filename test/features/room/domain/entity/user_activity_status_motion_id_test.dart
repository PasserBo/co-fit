import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motionId round-trips through the presence map', () {
    const status = UserActivityStatusEntity(
      activityState: UserActivityState.active,
      actionKey: 'strength',
      motionId: 'lunge',
      sessionId: 's1',
    );
    final map = userActivityStatusEntityToMap(status);
    expect(map['motionId'], 'lunge');
    expect(UserActivityStatusEntity.fromMap(map).motionId, 'lunge');
  });

  test('old clients without motionId still parse (null → type prototype)', () {
    final status = UserActivityStatusEntity.fromMap({
      'activityState': 'active',
      'actionKey': 'cardio',
    });
    expect(status.motionId, isNull);
    expect(
      userActivityStatusEntityToMap(status).containsKey('motionId'),
      isFalse,
    );
  });
}
