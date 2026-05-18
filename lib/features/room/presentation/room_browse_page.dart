import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/ably_state_machine.dart';
import '../../auth/presentation/user_bootstrap_provider.dart';
import '../data/room_event.dart';
import '../data/room_presence_member.dart';
import 'room_browser_provider.dart';
import 'room_main_page.dart';
import 'widgets/room_widgets.dart';

class RoomBrowsePage extends ConsumerStatefulWidget {
  const RoomBrowsePage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  ConsumerState<RoomBrowsePage> createState() => _RoomBrowsePageState();
}

class _RoomBrowsePageState extends ConsumerState<RoomBrowsePage> {
  late final PageController _pageController;
  bool _isPageControllerReady = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    unawaited(ref.read(ablyRuntimeProvider.notifier).initializeForUser(widget.userId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _isPageControllerReady = true;
      final joined = ref.read(userBootstrapProvider).joinedRoomIds;
      unawaited(
        ref.read(roomBrowserProvider.notifier).syncJoinedRooms(
              joined,
              userId: widget.userId,
            ),
      );
      _syncPageToFocusedRoom(
        joinedRoomIds: ref.read(roomBrowserProvider).joinedRoomIds,
        focusedRoomId: ref.read(roomBrowserProvider).focusedRoomId,
        animate: false,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<String>>(
      userBootstrapProvider.select((state) => state.joinedRoomIds),
      (_, joinedRoomIds) {
        unawaited(
          ref.read(roomBrowserProvider.notifier).syncJoinedRooms(
                joinedRoomIds,
                userId: widget.userId,
              ),
        );
      },
    );

    ref.listen<RoomBrowserState>(roomBrowserProvider, (_, next) {
      _syncPageToFocusedRoom(
        joinedRoomIds: next.joinedRoomIds,
        focusedRoomId: next.focusedRoomId,
      );
    });

    final runtime = ref.watch(ablyRuntimeProvider);
    final bootstrapState = ref.watch(userBootstrapProvider);
    final browserState = ref.watch(roomBrowserProvider);
    final joinedRoomIds = browserState.joinedRoomIds;
    final focusedRoomId = browserState.focusedRoomId;
    final focusedEvents = ref.watch(focusedRoomEventsProvider);
    final focusedPresence = ref.watch(focusedRoomPresenceProvider);

    if (bootstrapState.isBootstrapping && joinedRoomIds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Room Browser',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RoomMainPage(userId: widget.userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Open Controls'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RoomConnectionStateView(
                runtime: runtime,
                activeRoomId: focusedRoomId,
              ),
              if (browserState.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  browserState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: joinedRoomIds.isEmpty
              ? _EmptyJoinedRoomState(userId: widget.userId)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: joinedRoomIds.length,
                  onPageChanged: (index) {
                    ref
                        .read(roomBrowserProvider.notifier)
                        .setFocusedRoom(joinedRoomIds[index]);
                  },
                  itemBuilder: (context, index) {
                    final roomId = joinedRoomIds[index];
                    final isFocused = roomId == focusedRoomId;
                    final events = isFocused
                        ? focusedEvents
                        : ref.watch(roomEventsByIdProvider(roomId));
                    final members = isFocused
                        ? focusedPresence
                        : ref.watch(roomPresenceByIdProvider(roomId));
                    return _RoomBrowsePane(
                      roomId: roomId,
                      isFocused: isFocused,
                      events: events,
                      members: members,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _syncPageToFocusedRoom({
    required List<String> joinedRoomIds,
    required String? focusedRoomId,
    bool animate = true,
  }) {
    if (!_isPageControllerReady || !_pageController.hasClients) {
      return;
    }
    if (focusedRoomId == null || joinedRoomIds.isEmpty) {
      return;
    }
    final targetIndex = joinedRoomIds.indexOf(focusedRoomId);
    if (targetIndex < 0) {
      return;
    }
    final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
    if (currentPage == targetIndex) {
      return;
    }
    if (animate) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    _pageController.jumpToPage(targetIndex);
  }
}

class _RoomBrowsePane extends StatelessWidget {
  const _RoomBrowsePane({
    required this.roomId,
    required this.isFocused,
    required this.events,
    required this.members,
  });

  final String roomId;
  final bool isFocused;
  final List<RoomEvent> events;
  final List<RoomPresenceMember> members;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.meeting_room_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roomId,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(isFocused ? 'Focused' : 'Background'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        RoomPresenceCard(members: members),
        const SizedBox(height: 12),
        RoomEventTimelineCard(events: events),
      ],
    );
  }
}

class _EmptyJoinedRoomState extends StatelessWidget {
  const _EmptyJoinedRoomState({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'No joined rooms yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Join or create a room from the control console to start browsing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomMainPage(userId: userId),
                  ),
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('Open Room Controls'),
            ),
          ],
        ),
      ),
    );
  }
}
