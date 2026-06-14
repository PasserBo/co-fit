import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../../action/domain/entity/action_template_card.dart';
import '../../action/presentation/action_template_usecase_provider.dart';
import '../../action/presentation/widgets/action_template_launch_browser.dart';
import '../../auth/presentation/user_bootstrap_provider.dart';
import 'join_room_provider.dart';
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
  bool _isStartingTemplateAction = false;
  String? _startingTemplateId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(ablyRuntimeProvider.notifier).initializeForUser(widget.userId));
  }

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
          .read(joinRoomUsecaseProvider)
          .execute(roomId: roomId, userId: widget.userId);
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

  String? _resolveTargetRoomId(List<String> joinedRoomIds) {
    final manualRoomId = _roomIdController.text.trim();
    if (manualRoomId.isNotEmpty) {
      return manualRoomId;
    }
    if (joinedRoomIds.isNotEmpty) {
      return joinedRoomIds.first;
    }
    return null;
  }

  String _formatDuration(int durationSec) {
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    if (minutes <= 0) {
      return '${durationSec}s';
    }
    if (seconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  Future<void> _startTemplateCardAction({
    required ActionTemplateCard card,
    required List<String> joinedRoomIds,
  }) async {
    if (_isStartingTemplateAction) {
      return;
    }
    final targetRoomId = _resolveTargetRoomId(joinedRoomIds);
    if (targetRoomId == null) {
      setState(() {
        _errorMessage = '请先输入 roomId，或先加入一个房间再启动模板卡。';
      });
      return;
    }

    setState(() {
      _isStartingTemplateAction = true;
      _startingTemplateId = card.id;
      _errorMessage = null;
    });

    try {
      await ref.read(ablyRuntimeProvider.notifier).initializeForUser(widget.userId);
      await ref
          .read(selectTemplateCardUsecaseProvider)
          .execute(templateId: card.id);
      await ref
          .read(startTemplateCardActionUsecaseProvider)
          .execute(roomId: targetRoomId, userId: widget.userId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已在房间 $targetRoomId 启动模板卡：${card.name}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '模板卡启动失败: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingTemplateAction = false;
          _startingTemplateId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(userBootstrapProvider);
    final templateCardsState = ref.watch(templateCardsProvider);
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
        const SizedBox(height: 12),
        ActionTemplateLaunchBrowser(
          templateCardsState: templateCardsState,
          isStartingTemplateAction: _isStartingTemplateAction,
          startingTemplateId: _startingTemplateId,
          formatDuration: _formatDuration,
          onUseTemplateCard: (card) => unawaited(
            _startTemplateCardAction(card: card, joinedRoomIds: joinedRoomIds),
          ),
        ),
      ],
    );
  }
}
