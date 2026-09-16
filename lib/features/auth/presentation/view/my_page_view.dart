import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';

import '../../../action/presentation/action_template_usecase_provider.dart';
import '../../../action/provider/action_decks_provider.dart';
import '../../../action/presentation/view/workout_history_page_view.dart';
import '../../../action/provider/action_session_history_providers.dart';
import '../../../profile/domain/entity/user_profile_entity.dart';
import '../../../profile/provider/user_profile_provider.dart';
import '../../../profile/provider/delete_account_provider.dart';
import '../../../profile/provider/user_profile_repository_provider.dart';
import '../../domain/repository/auth_repository.dart';
import '../../usecase/sign_out_usecase.dart';
import '../user_bootstrap_provider.dart';
import '../widget/my_page_body.dart';

/// 「我的」页(10a 形象优先,内容收敛到已实现功能)。
/// 编辑形象为 stub(avatar feature 未实现,见 STATUS.md Stub 登记表)。
class MyPageView extends ConsumerWidget {
  const MyPageView({
    required this.user,
    required this.signOutUsecase,
    super.key,
  });

  final User user;
  final SignOutUsecase signOutUsecase;

  String get _handle {
    final id = user.uid;
    return id.length <= 6 ? id : id.substring(0, 6);
  }

  String _fallbackDisplayName() {
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return '匿名用户';
  }

  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    UserProfileEntity profile,
  ) async {
    final controller = TextEditingController(text: profile.nickname);
    final newNickname = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: UserProfileEntity.nicknameMaxLength,
          decoration: const InputDecoration(
            labelText: '昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newNickname == null ||
        newNickname.isEmpty ||
        newNickname == profile.nickname) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    try {
      await ref
          .read(updateProfileUsecaseProvider)
          .execute(profile.copyWith(nickname: newNickname));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('昵称保存失败,请重试')));
      }
    }
  }

  /// 删除账号(Apple 上架要求)。二次确认 → 重认证 → 清数据 → 注销。
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除账号?'),
        content: const Text(
          '将永久删除:你的资料与昵称、全部牌组与自建卡、运动历史记录,'
          '并退出所有房间(你创建的房间会被解散)。\n\n此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '删除账号',
              style: TextStyle(color: colors.statusDanger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref
          .read(deleteAccountUsecaseProvider)
          .execute(userId: user.uid);
      // 成功后 authStateChanges 会把 AuthGate 切回登录页,无需手动导航。
    } on AuthCancelledException {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on ReauthenticationRequiredException {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('为安全起见,请先退出登录并重新登录后再删除账号')),
          );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('删除失败:$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomCount =
        ref.watch(userBootstrapProvider.select((s) => s.joinedRoomIds.length));
    final deckCount =
        ref.watch(actionDecksProvider).value?.length ?? 0;
    final cardCount = ref.watch(templateCardsProvider).value?.length ?? 0;
    final profile = ref.watch(userProfileProvider).value;
    final hasSessionData = ref.watch(recentSessionsProvider).hasValue;
    final totals = ref.watch(sessionTotalsProvider);

    return Scaffold(
      body: SafeArea(
        child: MyPageBody(
          displayName: profile?.nickname ?? _fallbackDisplayName(),
          handle: _handle,
          email: user.email,
          roomCount: roomCount,
          deckCount: deckCount,
          cardCount: cardCount,
          sessionCount: hasSessionData ? totals.count : null,
          totalDurationMin:
              hasSessionData ? totals.totalDurationSec ~/ 60 : null,
          onEditAvatar: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('编辑形象:开发中')),
              );
          },
          onEditNickname: profile == null
              ? null
              : () => _editNickname(context, ref, profile),
          onOpenHistory: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WorkoutHistoryPageView(),
              ),
            );
          },
          onSignOut: () async {
            await signOutUsecase.execute();
          },
          onDeleteAccount: () => _deleteAccount(context, ref),
        ),
      ),
    );
  }
}
