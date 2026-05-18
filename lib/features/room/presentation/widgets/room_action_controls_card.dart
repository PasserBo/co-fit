import 'package:flutter/material.dart';

class RoomActionControlsCard extends StatelessWidget {
  const RoomActionControlsCard({
    required this.isJoined,
    required this.actionOptions,
    required this.selectedAction,
    required this.onActionChanged,
    required this.durationOptions,
    required this.selectedDurationSec,
    required this.onDurationChanged,
    required this.remainingSec,
    required this.isTimerRunning,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    super.key,
  });

  final bool isJoined;
  final List<String> actionOptions;
  final String selectedAction;
  final ValueChanged<String> onActionChanged;
  final List<int> durationOptions;
  final int selectedDurationSec;
  final ValueChanged<int> onDurationChanged;
  final int remainingSec;
  final bool isTimerRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Event Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedAction,
              items: actionOptions
                  .map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(action),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isJoined
                  ? (value) {
                      if (value != null) {
                        onActionChanged(value);
                      }
                    }
                  : null,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: selectedDurationSec,
              items: durationOptions
                  .map(
                    (duration) => DropdownMenuItem(
                      value: duration,
                      child: Text('$duration sec'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isJoined
                  ? (value) {
                      if (value != null) {
                        onDurationChanged(value);
                      }
                    }
                  : null,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: $remainingSec sec',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: isJoined ? onStart : null,
                  child: const Text('Start'),
                ),
                OutlinedButton(
                  onPressed: isJoined && isTimerRunning ? onPause : null,
                  child: const Text('Pause'),
                ),
                OutlinedButton(
                  onPressed: isJoined && !isTimerRunning && remainingSec > 0
                      ? onResume
                      : null,
                  child: const Text('Resume'),
                ),
                OutlinedButton(
                  onPressed: isJoined ? onComplete : null,
                  child: const Text('Complete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
