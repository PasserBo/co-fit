import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/avatar_motion.dart';
import 'avatar_renderer.dart';
import 'motion_clip_library.dart';
import 'rig/motion_clip.dart';
import 'rig/rig.dart';
import 'rig_avatar_painter.dart';

/// Flutter 原生实现:豆豆骨架(Rig)+ clip 数据(MotionClipLibrary)+ CustomPaint。
/// 一个小人一个 AnimationController;状态切换从 0 重启,×1 过渡播完回调编排器。
class VectorAvatarRenderer extends AvatarRenderer {
  const VectorAvatarRenderer();

  @override
  Widget build({
    required AvatarMotion motion,
    required AvatarAppearance appearance,
    required double height,
    double phaseSeed = 0,
    VoidCallback? onOneShotComplete,
    Key? key,
  }) {
    return VectorAvatarFigure(
      key: key,
      motion: motion,
      appearance: appearance,
      height: height,
      phaseSeed: phaseSeed,
      onOneShotComplete: onOneShotComplete,
    );
  }
}

class VectorAvatarFigure extends StatefulWidget {
  const VectorAvatarFigure({
    required this.motion,
    required this.appearance,
    required this.height,
    this.phaseSeed = 0,
    this.onOneShotComplete,
    super.key,
  });

  final AvatarMotion motion;
  final AvatarAppearance appearance;
  final double height;
  final double phaseSeed;
  final VoidCallback? onOneShotComplete;

  /// 视框 80×100,宽高比固定。
  static const aspectRatio = Rig.viewWidth / Rig.viewHeight;

  @override
  State<VectorAvatarFigure> createState() => _VectorAvatarFigureState();
}

class _VectorAvatarFigureState extends State<VectorAvatarFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late MotionClip _clip = MotionClipLibrary.resolve(widget.motion);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_clip.loop) {
        widget.onOneShotComplete?.call();
      }
    });
    _restart();
  }

  @override
  void didUpdateWidget(VectorAvatarFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      _clip = MotionClipLibrary.resolve(widget.motion);
      _restart();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _tempoMultiplier(AvatarTempo tempo) => switch (tempo) {
    AvatarTempo.slow => CoFitDecor.tempoSlow,
    AvatarTempo.standard => 1.0,
    AvatarTempo.fast => CoFitDecor.tempoFast,
  };

  Duration _durationFor(AvatarMotion motion, MotionClip clip) {
    if (motion.state == AvatarMotionState.exercise) {
      return clip.period * _tempoMultiplier(motion.tempo);
    }
    return clip.period;
  }

  void _restart() {
    _controller
      ..stop()
      ..duration = _durationFor(widget.motion, _clip)
      ..reset();
    if (_clip.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(
          widget.height * VectorAvatarFigure.aspectRatio,
          widget.height,
        ),
        painter: RigAvatarPainter(
          clip: _clip,
          appearance: widget.appearance,
          animation: _controller,
          // 只有 loop 需要相位偏移;×1 过渡必须从头播
          phaseSeed: _clip.loop ? widget.phaseSeed : 0,
        ),
      ),
    );
  }
}
