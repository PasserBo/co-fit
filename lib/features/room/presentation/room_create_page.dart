import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/room_info_entity.dart';
import 'create_room_provider.dart';

class RoomCreatePage extends ConsumerWidget {
  const RoomCreatePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Create a room',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Set room name, visibility, and description.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: !state.isSubmitting,
            onChanged: notifier.updateName,
            decoration: InputDecoration(
              labelText: 'Room Name',
              border: const OutlineInputBorder(),
              helperText: state.name.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.visibility,
            items: RoomVisibility.allowed
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(growable: false),
            onChanged: state.isSubmitting
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    notifier.updateVisibility(value);
                  },
            decoration: const InputDecoration(
              labelText: 'Visibility',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !state.isSubmitting,
            onChanged: notifier.updateDescription,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () {
                    notifier.submit(ownerId: userId);
                  },
            child: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Room'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (state.createdRoomId != null &&
              state.createdShareLinkHash != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room created successfully',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText('roomId: ${state.createdRoomId}'),
                    const SizedBox(height: 6),
                    SelectableText(
                      'shareLinkHash: ${state.createdShareLinkHash}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
