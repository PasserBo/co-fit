import 'package:flutter/material.dart';

import '../../domain/entity/room_presence_member.dart';

class RoomPresenceCard extends StatelessWidget {
  const RoomPresenceCard({
    required this.members,
    super.key,
  });

  final List<RoomPresenceMember> members;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Online Members (${members.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Text('No members online yet.')
            else
              ...members.map((member) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.userId),
                  subtitle: Text('clientId: ${member.clientId}'),
                );
              }),
          ],
        ),
      ),
    );
  }
}
