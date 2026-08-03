import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/renderer/avatar_renderer.dart';
import '../presentation/renderer/vector_avatar_renderer.dart';

/// 动画实现的 DI 绑定 —— 换 Rive/Lottie 实现时只改这里。
final avatarRendererProvider = Provider<AvatarRenderer>((ref) {
  return const VectorAvatarRenderer();
});
