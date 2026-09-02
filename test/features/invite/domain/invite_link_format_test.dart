import 'package:cofit/features/invite/domain/entity/invite_link_entity.dart';
import 'package:cofit/features/invite/domain/invite_link_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteLinkFormat', () {
    test('build → tryParse round-trip', () {
      final uri = InviteLinkFormat.build(
        roomId: 'room-123',
        hash: 'abc123def456',
      );

      expect(uri.scheme, 'cofit');
      expect(uri.host, 'room');
      expect('$uri', 'cofit://room/room-123?h=abc123def456');

      final parsed = InviteLinkFormat.tryParse(uri);
      expect(
        parsed,
        const InviteLinkEntity(roomId: 'room-123', hash: 'abc123def456'),
      );
    });

    test('rejects wrong scheme / host', () {
      expect(
        InviteLinkFormat.tryParse(Uri.parse('https://room/abc?h=x')),
        isNull,
      );
      expect(
        InviteLinkFormat.tryParse(Uri.parse('cofit://card/abc?h=x')),
        isNull,
      );
    });

    test('rejects missing roomId or hash', () {
      expect(
        InviteLinkFormat.tryParse(Uri.parse('cofit://room?h=x')),
        isNull,
      );
      expect(
        InviteLinkFormat.tryParse(Uri.parse('cofit://room/abc')),
        isNull,
      );
      expect(
        InviteLinkFormat.tryParse(Uri.parse('cofit://room/abc?h=')),
        isNull,
      );
    });

    test('rejects extra path segments', () {
      expect(
        InviteLinkFormat.tryParse(Uri.parse('cofit://room/abc/def?h=x')),
        isNull,
      );
    });
  });
}
