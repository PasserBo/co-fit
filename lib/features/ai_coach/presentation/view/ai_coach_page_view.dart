import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../provider/ai_coach_providers.dart';
import '../../provider/coach_chat_controller.dart';
import '../widget/coach_beta_badge.dart';
import '../widget/coach_chat_entry.dart';
import '../widget/coach_composer.dart';
import '../widget/coach_consent_panel.dart';

/// 预置问题:覆盖总结 / 计划 / 列表 / 单选问卷四种卡片形态,便于对比日志。
const coachPresetPrompts = [
  '这周我练得怎么样?',
  '帮我排一个明天 15 分钟的训练计划',
  '我最常做哪些动作?哪些很久没练了?',
  '问我 3 个问题,推荐适合我的训练强度',
];

/// beta「AI 教练」(change add-ai-coach-beta;运动历史页 push 进入)。
/// 离开即 dispose 控制器,对话不保存;日志文件留在设备上。
class AiCoachPageView extends ConsumerStatefulWidget {
  const AiCoachPageView({super.key});

  @override
  ConsumerState<AiCoachPageView> createState() => _AiCoachPageViewState();
}

class _AiCoachPageViewState extends ConsumerState<AiCoachPageView> {
  bool? _consented;
  CoachChatController? _controller;
  Object? _startError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConsent());
  }

  Future<void> _loadConsent() async {
    final bool consented = await ref
        .read(coachConsentRepositoryProvider)
        .hasConsented();
    if (!mounted) {
      return;
    }
    setState(() => _consented = consented);
    if (consented) {
      await _startSession();
    }
  }

  Future<void> _accept() async {
    await ref.read(coachConsentRepositoryProvider).markConsented();
    if (!mounted) {
      return;
    }
    setState(() => _consented = true);
    await _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _startError = null);
    try {
      final CoachChatController controller = await ref.read(
        createCoachChatProvider,
      )();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) {
        setState(() => _startError = error);
      }
    }
  }

  Future<void> _exportLog() async {
    final CoachChatController? controller = _controller;
    final String? path = controller?.log.filePath;
    if (controller == null || path == null) {
      return;
    }
    await controller.log.flush();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: 'CoFit AI 教练会话日志'),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CoachChatController? controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingSm,
          children: [Text('AI 教练'), CoachBetaBadge()],
        ),
        actions: [
          if (controller != null)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => IconButton(
                tooltip: '导出日志',
                icon: const Icon(Icons.ios_share),
                onPressed:
                    controller.hasTurns && controller.log.filePath != null
                    ? _exportLog
                    : null,
              ),
            ),
        ],
      ),
      body: SafeArea(child: _body(controller)),
    );
  }

  Widget _body(CoachChatController? controller) {
    if (_consented == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_consented == false) {
      return CoachConsentPanel(
        onAccept: _accept,
        onDecline: () => Navigator.of(context).pop(),
      );
    }
    if (_startError != null) {
      return _StartError(onRetry: _startSession);
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: controller.entries.isEmpty
                ? const _EmptyChat()
                : ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(CoFitDimens.spacingLg),
                    children: [
                      for (final CoachEntry entry
                          in controller.entries.reversed)
                        CoachChatEntry(
                          key: ObjectKey(entry.surface ?? entry),
                          entry: entry,
                        ),
                    ],
                  ),
          ),
          if (controller.busy) const LinearProgressIndicator(),
          CoachComposer(
            presets: coachPresetPrompts,
            enabled: !controller.busy,
            onSend: (text, preset) =>
                unawaited(controller.send(text, preset: preset)),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacing2xl),
        child: Text(
          '就你最近的运动记录提问,\n教练会用文字或卡片回答。',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
        ),
      ),
    );
  }
}

class _StartError extends StatelessWidget {
  const _StartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          Text(
            '运动记录加载失败',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
          ),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
