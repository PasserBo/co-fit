import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/floating_dock.dart';

/// 「我的」页纯展示层(10a 形象优先,2026-08-01 决议:内容收敛到已实现功能)。
/// 英雄区(占位小人 + 名字 + 编辑形象)+ 真实数据统计块 + 账号分组 + 退出登录。
/// 10a 中的 累计时长/连续打卡/通知隐私开关 等未实现功能不做。
class MyPageBody extends StatelessWidget {
  const MyPageBody({
    required this.displayName,
    required this.handle,
    required this.roomCount,
    required this.deckCount,
    required this.cardCount,
    this.email,
    this.onEditAvatar,
    this.onSignOut,
    super.key,
  });

  final String displayName;

  /// @handle(uid 截断,G5 占位)。
  final String handle;
  final int roomCount;
  final int deckCount;
  final int cardCount;
  final String? email;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CoFitDimens.spacingLg,
        CoFitDimens.spacingSm,
        CoFitDimens.spacingLg,
        CoFitDimens.spacingLg,
      ),
      children: [
        Padding(
          // 标题行给悬浮 dock 让位(同牌库页)
          padding: const EdgeInsets.only(
            left: FloatingDock.collapsedWidth + CoFitDimens.spacingSm,
            bottom: CoFitDimens.spacingSm,
          ),
          child: Text('我的', style: textTheme.titleLarge),
        ),
        _HeroCard(
          displayName: displayName,
          handle: handle,
          onEditAvatar: onEditAvatar,
        ),
        const SizedBox(height: CoFitDimens.spacingMd),
        Row(
          spacing: CoFitDimens.spacingSm,
          children: [
            Expanded(
              child: _StatTile(
                value: '$roomCount',
                label: '加入房间',
                valueColor: colors.primaryMain,
              ),
            ),
            Expanded(
              child: _StatTile(
                value: '$deckCount',
                label: '牌组',
                valueColor: colors.statusPaused,
              ),
            ),
            Expanded(
              child: _StatTile(
                value: '$cardCount',
                label: '卡牌',
                valueColor: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        _GroupLabel('账号'),
        _SettingsGroup(
          children: [
            _SettingsRow(
              iconColor: colors.statusPaused,
              iconBg: colors.typeCoreSubtle,
              icon: Icons.mail_outline_rounded,
              label: '邮箱',
              trailing: email ?? '未绑定',
            ),
          ],
        ),
        const SizedBox(height: CoFitDimens.spacingLg),
        // 退出登录:独立 danger 卡片(README §5)
        GestureDetector(
          onTap: onSignOut,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: CoFitDimens.spacingMd,
            ),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
              border: Border.all(
                color: colors.borderSubtle,
                width: CoFitDimens.borderWidthHairline,
              ),
            ),
            child: Center(
              child: Text(
                '退出登录',
                style: textTheme.labelLarge
                    ?.copyWith(color: colors.statusDanger),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.displayName,
    required this.handle,
    this.onEditAvatar,
  });

  final String displayName;
  final String handle;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // #10a hero 渐变底:surface → deep 的斜向过渡
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.bgSurface, colors.bgDeep],
        ),
        borderRadius: BorderRadius.circular(CoFitDimens.radiusXl),
        border: Border.all(
          color: colors.borderSubtle,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 顶部 lime 光晕
          Positioned(
            top: -CoFitDimens.sizeHeroGlow / 4,
            child: Container(
              width: CoFitDimens.sizeHeroGlow,
              height: CoFitDimens.sizeHeroGlow,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primaryMain.withValues(alpha: CoFitOpacities.glow),
                    colors.primaryMain.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CoFitDimens.spacingXl),
            child: Column(
              children: [
                _HeroFigure(color: colors.primaryMain),
                const SizedBox(height: CoFitDimens.spacingMd),
                Text(
                  displayName,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingXs),
                Text(
                  '@$handle',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CoFitDimens.spacingMd),
                GestureDetector(
                  onTap: onEditAvatar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CoFitDimens.spacingLg,
                      vertical: CoFitDimens.spacingSm,
                    ),
                    decoration: ShapeDecoration(
                      color: colors.primaryMain,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      '编辑形象',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.primaryOn,
                        fontWeight: CoFitFontWeights.heading,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 英雄区占位小人(头 + 身),比例按 #10a mock 从总高推导;接 Rive 后替换。
class _HeroFigure extends StatelessWidget {
  const _HeroFigure({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const height = CoFitDimens.sizeFigureHero;
    final head = height * 0.38;
    final bodyW = height * 0.47;
    final bodyH = height * 0.58;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: head,
          height: head,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: CoFitOpacities.subtle),
                spreadRadius: CoFitDimens.spacingXs,
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.04),
        Container(
          width: bodyW,
          height: bodyH,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: CoFitDimens.spacingMd),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(color: valueColor),
          ),
          const SizedBox(height: CoFitDimens.spacingXs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Padding(
      padding: const EdgeInsets.only(
        left: CoFitDimens.spacingXs,
        bottom: CoFitDimens.spacingSm,
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: colors.textDisabled),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: CoFitDimens.borderWidthHairline,
                color: colors.borderSubtle,
                indent: CoFitDimens.sizeCardIconBlock +
                    CoFitDimens.spacingMd * 2,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(CoFitDimens.spacingMd),
      child: Row(
        spacing: CoFitDimens.spacingMd,
        children: [
          Container(
            width: CoFitDimens.sizeCardIconBlock,
            height: CoFitDimens.sizeCardIconBlock,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
            ),
            child: Icon(icon, size: CoFitDimens.sizeCardIcon, color: iconColor),
          ),
          Expanded(
            child: Text(label, style: textTheme.bodyMedium, maxLines: 1),
          ),
          Flexible(
            child: Text(
              trailing,
              style:
                  textTheme.bodySmall?.copyWith(color: colors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
