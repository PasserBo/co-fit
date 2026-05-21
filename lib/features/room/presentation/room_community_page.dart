import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/user_bootstrap_provider.dart';
import '../data/room_repository_provider.dart';
import 'room_create_page.dart';

class RoomCommunityPage extends ConsumerStatefulWidget {
  const RoomCommunityPage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  ConsumerState<RoomCommunityPage> createState() => _RoomCommunityPageState();
}

class _RoomCommunityPageState extends ConsumerState<RoomCommunityPage> {
  final TextEditingController _roomIdController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _errorMessage = 'roomId is required';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(firebaseRoomRepositoryProvider)
          .joinRoomWithMembership(roomId: roomId, userId: widget.userId);
      await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined room: $roomId')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to join room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _openCreateRoom() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomCreatePage(userId: widget.userId),
      ),
    );
    if (!mounted) {
      return;
    }
    await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(userBootstrapProvider);
    final joinedRoomIds = bootstrapState.joinedRoomIds;
    final effectiveError = _errorMessage ?? bootstrapState.error;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Community',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Search, join, or create a room.'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joined Rooms (${joinedRoomIds.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (bootstrapState.isBootstrapping)
                  const LinearProgressIndicator()
                else if (joinedRoomIds.isEmpty)
                  const Text('No joined rooms yet.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: joinedRoomIds
                        .map(
                          (roomId) => Chip(
                            avatar: const Icon(
                              Icons.meeting_room_outlined,
                              size: 16,
                            ),
                            label: Text(roomId),
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roomIdController,
                  enabled: !_isJoining,
                  decoration: const InputDecoration(
                    labelText: 'roomId',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isJoining ? null : _joinRoom,
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Join Room'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openCreateRoom,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Room'),
                      ),
                    ),
                  ],
                ),
                if (effectiveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    effectiveError,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
