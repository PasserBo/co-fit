import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../provider/room_connection_status_provider.dart';

/// 房间页连接状态提示条(纯展示):live 时不渲染;
/// connecting = 中性「连接中」,offline = amber「离线」,unavailable = danger。
/// 悬浮在顶栏下方,不挤压场景布局。
class RoomConnectionBanner extends StatelessWidget {
  const RoomConnectionBanner({required this.status, super.key});

  final RoomConnectionStatus status;

  static String? labelOf(RoomConnectionStatus status) {
    switch (status) {
      case RoomConnectionStatus.live:
        return null;
      case RoomConnectionStatus.connecting:
        return '正在连接房间…';
      case RoomConnectionStatus.offline:
        return '网络已断开,恢复后自动重连';
      case RoomConnectionStatus.unavailable:
        return '实时服务暂不可用,看不到其他人的状态';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = labelOf(status);
    if (label == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final (Color accent, IconData icon) = switch (status) {
      RoomConnectionStatus.connecting => (
        colors.textSecondary,
        Icons.sync_rounded,
      ),
      RoomConnectionStatus.offline => (
        colors.statusPaused,
        Icons.wifi_off_rounded,
      ),
      RoomConnectionStatus.unavailable => (
        colors.statusDanger,
        Icons.cloud_off_rounded,
      ),
      RoomConnectionStatus.live => (colors.textSecondary, Icons.check),
    };

    return AnimatedSwitcher(
      duration: CoFitMotion.dockExpand,
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(
          horizontal: CoFitDimens.spacingMd,
          vertical: CoFitDimens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          border: Border.all(
            color: accent.withValues(alpha: CoFitOpacities.border),
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingSm,
          children: [
            Icon(icon, size: CoFitDimens.sizeCardIcon, color: accent),
            Flexible(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(color: accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
