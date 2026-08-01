import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../action/presentation/action_template_usecase_provider.dart';
import '../../../action/provider/action_decks_provider.dart';
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

  String get _displayName {
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return '匿名用户';
  }

  String get _handle {
    final id = user.uid;
    return id.length <= 6 ? id : id.substring(0, 6);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomCount =
        ref.watch(userBootstrapProvider.select((s) => s.joinedRoomIds.length));
    final deckCount =
        ref.watch(actionDecksProvider).value?.length ?? 0;
    final cardCount = ref.watch(templateCardsProvider).value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: MyPageBody(
          displayName: _displayName,
          handle: _handle,
          email: user.email,
          roomCount: roomCount,
          deckCount: deckCount,
          cardCount: cardCount,
          onEditAvatar: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('编辑形象:开发中')),
              );
          },
          onSignOut: () async {
            await signOutUsecase.execute();
          },
        ),
      ),
    );
  }
}
