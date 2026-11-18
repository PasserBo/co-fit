// AuthGate 未登录分支 × 登录前演示房间(规格 welcome-tour:
// 「首次启动先进演示房间」「演示只出现一次」「邀请链接优先于演示」)。
// 门控决策的纯函数单测见 unauthenticated_stage_test.dart,这里验证接线。
import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_provider.dart';
import 'package:cofit/core/theme/cofit_colors.dart';
import 'package:cofit/core/widget/brand_splash.dart';
import 'package:cofit/features/auth/presentation/auth_gate_page.dart';
import 'package:cofit/features/auth/presentation/view/login_page_view.dart';
import 'package:cofit/features/auth/provider/auth_state_provider.dart';
import 'package:cofit/features/invite/domain/entity/invite_link_entity.dart';
import 'package:cofit/features/invite/provider/pending_invite_provider.dart';
import 'package:cofit/features/profile/domain/entity/user_profile_entity.dart';
import 'package:cofit/features/profile/provider/user_profile_provider.dart';
import 'package:cofit/features/welcome_tour/data/in_memory_welcome_tour_seen_repository.dart';
import 'package:cofit/features/welcome_tour/presentation/view/welcome_tour_view.dart';
import 'package:cofit/features/welcome_tour/provider/welcome_tour_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只有 uid 会被门控用到;其余成员不该被碰,碰到就抛。
class _FakeUser implements User {
  @override
  String get uid => 'u_test';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 不接 app_links:初值由测试给,运行中可用 [emit] 模拟链接到达。
class _FakePendingInvite extends PendingInviteNotifier {
  _FakePendingInvite(this._initial);

  final InviteLinkEntity? _initial;

  @override
  InviteLinkEntity? build() => _initial;

  void emit(InviteLinkEntity invite) => state = invite;
}

const _invite = InviteLinkEntity(roomId: 'r1', hash: 'h1');

/// 等 AnimatedSwitcher 交叉淡出结束,不用 pumpAndSettle(splash 小人常驻动画)。
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<_FakePendingInvite> _pumpGate(
  WidgetTester tester, {
  required InMemoryWelcomeTourSeenRepository seenRepo,
  User? user,
  InviteLinkEntity? invite,
}) async {
  final pendingInvite = _FakePendingInvite(invite);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(user)),
        pendingInviteProvider.overrideWith(() => pendingInvite),
        welcomeTourSeenRepositoryProvider.overrideWithValue(seenRepo),
        featureFlagsProvider.overrideWith((ref) async => FeatureFlags.defaults),
        // 已登录分支停在「profile 加载中」的 splash,够验证不出演示 + 打标。
        userProfileProvider.overrideWith(
          (ref) => const Stream<UserProfileEntity?>.empty(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
        ).copyWith(extensions: [CoFitColors.dark]),
        home: const AuthGatePage(),
      ),
    ),
  );
  await _settle(tester);
  return pendingInvite;
}

void main() {
  group('首次启动先进演示房间', () {
    testWidgets('全新安装首次打开 → 演示房间,不是登录页', (tester) async {
      await _pumpGate(tester, seenRepo: InMemoryWelcomeTourSeenRepository());

      expect(find.byType(WelcomeTourView), findsOneWidget);
      expect(find.byType(LoginPageView), findsNothing);
    });

    testWidgets('标记读出来之前是 splash,不闪登录页', (tester) async {
      final pendingInvite = _FakePendingInvite(null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            pendingInviteProvider.overrideWith(() => pendingInvite),
            welcomeTourSeenRepositoryProvider.overrideWithValue(
              InMemoryWelcomeTourSeenRepository(),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
            ).copyWith(extensions: [CoFitColors.dark]),
            home: const AuthGatePage(),
          ),
        ),
      );
      // authState 已有值、seen 仍在 Future 里:这一帧必须是 splash。
      await tester.pump();
      expect(find.byType(BrandSplash), findsOneWidget);
      expect(find.byType(LoginPageView), findsNothing);
      expect(find.byType(WelcomeTourView), findsNothing);
    });

    testWidgets('已登录用户不受影响,且登录即视为看过', (tester) async {
      final repo = InMemoryWelcomeTourSeenRepository();
      await _pumpGate(tester, seenRepo: repo, user: _FakeUser());

      expect(find.byType(WelcomeTourView), findsNothing);
      expect(find.byType(LoginPageView), findsNothing);
      expect(repo.seen, isTrue);
    });

    testWidgets('曾经登录过又退出(标记已为 true)→ 登录页', (tester) async {
      await _pumpGate(
        tester,
        seenRepo: InMemoryWelcomeTourSeenRepository(seen: true),
      );

      expect(find.byType(LoginPageView), findsOneWidget);
      expect(find.byType(WelcomeTourView), findsNothing);
    });
  });

  group('演示只出现一次', () {
    testWidgets('跳过 / 走完演示后再打开(标记为 true)→ 登录页', (tester) async {
      await _pumpGate(
        tester,
        seenRepo: InMemoryWelcomeTourSeenRepository(seen: true),
      );

      expect(find.byType(LoginPageView), findsOneWidget);
    });

    testWidgets('演示中途杀掉 App(标记仍为 false)→ 再次演示', (tester) async {
      await _pumpGate(tester, seenRepo: InMemoryWelcomeTourSeenRepository());

      expect(find.byType(WelcomeTourView), findsOneWidget);
    });

    testWidgets('光是看到演示不打标,只有跳过/登录才打', (tester) async {
      final repo = InMemoryWelcomeTourSeenRepository();
      await _pumpGate(tester, seenRepo: repo);

      expect(find.byType(WelcomeTourView), findsOneWidget);
      expect(repo.seen, isFalse);
    });

    testWidgets('一进来就跳过 → 立即登录页,并落下已看过', (tester) async {
      final repo = InMemoryWelcomeTourSeenRepository();
      await _pumpGate(tester, seenRepo: repo);
      expect(find.text(WelcomeTourView.titleLabel), findsOneWidget);

      await tester.tap(find.text(WelcomeTourView.skipLabel));
      await _settle(tester);

      expect(find.byType(LoginPageView), findsOneWidget);
      expect(find.byType(WelcomeTourView), findsNothing);
      expect(repo.seen, isTrue);
    });
  });

  group('邀请链接优先于演示', () {
    testWidgets('点邀请链接首次打开 → 登录页,并且此后不再演示', (tester) async {
      final repo = InMemoryWelcomeTourSeenRepository();
      await _pumpGate(tester, seenRepo: repo, invite: _invite);

      expect(find.byType(LoginPageView), findsOneWidget);
      expect(find.byType(WelcomeTourView), findsNothing);
      expect(repo.seen, isTrue);
    });

    testWidgets('演示进行中收到邀请链接 → 立即切到登录页并打标', (tester) async {
      final repo = InMemoryWelcomeTourSeenRepository();
      final pendingInvite = await _pumpGate(tester, seenRepo: repo);
      expect(find.byType(WelcomeTourView), findsOneWidget);

      pendingInvite.emit(_invite);
      await _settle(tester);

      expect(find.byType(LoginPageView), findsOneWidget);
      expect(find.byType(WelcomeTourView), findsNothing);
      expect(repo.seen, isTrue);
    });
  });
}
