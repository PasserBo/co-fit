import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 建房成功态(#20b「创建即邀请」):✓ burst 徽章 + 「已就绪」+
/// 链接卡(等宽截断 + 复制小按钮)+ 主 CTA 分享 + 次级「先进房间看看」。
class RoomCreatedSheet extends StatelessWidget {
  const RoomCreatedSheet({
    required this.roomName,
    required this.link,
    super.key,
  });

  /// 进房后在房间页上弹出(建房页已收起);「先进房间看看」= 关闭。
  static Future<void> show(
    BuildContext context, {
    required String roomName,
    required Uri link,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CoFitDimens.spacingXl),
          child: SingleChildScrollView(
            child: RoomCreatedSheet(roomName: roomName, link: link),
          ),
        ),
      ),
    );
  }

  final String roomName;
  final Uri link;

  String get _shareText => '来 CoFit 一起运动!加入我的房间「$roomName」:$link';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _BurstBadge()),
        const SizedBox(height: CoFitDimens.spacingSm),
        Text(
          '「$roomName」已就绪',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: CoFitFontWeights.heading,
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingXs),
        Text(
          '把链接发给朋友,他们一键即可加入',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoFitDimens.spacingMd,
            vertical: CoFitDimens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colors.bgDeep,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
            border: Border.all(
              color: colors.borderStrong,
              width: CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Row(
            spacing: CoFitDimens.spacingSm,
            children: [
              Icon(
                Icons.link_rounded,
                size: CoFitDimens.sizeCardIcon,
                color: colors.primaryMain,
              ),
              Expanded(
                child: Text(
                  '$link',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '$link'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('已复制')));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CoFitDimens.spacingSm,
                    vertical: CoFitDimens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
                    border: Border.all(
                      color: colors.borderStrong,
                      width: CoFitDimens.borderWidthHairline,
                    ),
                  ),
                  child: Text(
                    '复制',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: CoFitFontWeights.heading,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        SizedBox(
          height: CoFitDimens.sizeMinTapTarget,
          child: FilledButton.icon(
            onPressed: () {
              SharePlus.instance.share(ShareParams(text: _shareText));
            },
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('分享给朋友'),
          ),
        ),
        const SizedBox(height: CoFitDimens.spacingXs),
        SizedBox(
          height: CoFitDimens.sizeMinTapTarget,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('先进房间看看', style: TextStyle(color: colors.textTertiary)),
          ),
        ),
      ],
    );
  }
}

/// ✓ 圆徽 + 外扩光圈动画(#20b,burstRing 周期 token)。
class _BurstBadge extends StatefulWidget {
  const _BurstBadge();

  @override
  State<_BurstBadge> createState() => _BurstBadgeState();
}

class _BurstBadgeState extends State<_BurstBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CoFitMotion.burstRing,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return SizedBox(
      width: CoFitDimens.sizeSuccessBadge,
      height: CoFitDimens.sizeSuccessBadge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: CoFitDecor.fanFocusScale)
                .animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                ),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: CoFitOpacities.border,
                end: 0,
              ).animate(_controller),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primaryMain,
                    width: CoFitDimens.borderWidthFocus,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: CoFitDimens.sizeSuccessBadge,
            height: CoFitDimens.sizeSuccessBadge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primarySubtle,
              border: Border.all(
                color: colors.primaryBorder,
                width: CoFitDimens.borderWidthHairline,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              color: colors.primaryMain,
              size: CoFitDimens.sizeCheckBadge,
            ),
          ),
        ],
      ),
    );
  }
}
