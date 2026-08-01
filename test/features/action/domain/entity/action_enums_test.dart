import 'package:cofit/features/action/domain/entity/action_source.dart';
import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionType.fromRaw', () {
    test('maps known english values regardless of casing/suffix', () {
      expect(ActionType.fromRaw('strength_basic'), ActionType.strength);
      expect(ActionType.fromRaw('CARDIO_hiit'), ActionType.cardio);
      expect(ActionType.fromRaw('core'), ActionType.core);
      expect(ActionType.fromRaw('flexibility_stretch'), ActionType.flexibility);
      expect(ActionType.fromRaw('flex'), ActionType.flexibility);
    });

    test('maps chinese labels', () {
      expect(ActionType.fromRaw('力量训练'), ActionType.strength);
      expect(ActionType.fromRaw('有氧'), ActionType.cardio);
    });

    test('falls back on unknown values', () {
      expect(ActionType.fromRaw('yoga_dance'), ActionType.fallback);
      expect(ActionType.fromRaw(''), ActionType.fallback);
    });
  });

  group('ActionSource.fromRaw', () {
    test('defaults to official when missing or unknown', () {
      expect(ActionSource.fromRaw(null), ActionSource.official);
      expect(ActionSource.fromRaw(''), ActionSource.official);
      expect(ActionSource.fromRaw('something'), ActionSource.official);
    });

    test('maps custom and friendShared variants', () {
      expect(ActionSource.fromRaw('custom'), ActionSource.custom);
      expect(ActionSource.fromRaw('friendShared'), ActionSource.friendShared);
      expect(ActionSource.fromRaw('friend_shared'), ActionSource.friendShared);
    });
  });
}
