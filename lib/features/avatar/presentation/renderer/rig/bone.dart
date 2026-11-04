/// 豆豆骨骼树(docs/avatar_bean_spec.md §1):14 根里 root/pelvis 无几何,
/// 其余 12 根在正面/侧面共用;侧面时 L = 近侧、R = 远侧。
enum Bone {
  root,
  pelvis,
  spine,
  head,
  uarmL,
  farmL,
  uarmR,
  farmR,
  thighL,
  shinL,
  thighR,
  shinR;

  /// 侧视时的远侧肢体(R 侧)= 主体色 @80%(spec §3)。
  bool get isRightSide => switch (this) {
    Bone.uarmR || Bone.farmR || Bone.thighR || Bone.shinR => true,
    _ => false,
  };
}

/// 视角:同一棵树,只换四肢排布;朝左 = 侧面 scaleX(−1)(spec §3)。
enum Facing { front, side }

/// 挂点(spec §2):物品只认挂点,不认几何。P1 仅定义坐标,P3 开始挂物品。
enum Socket { crown, face, chest, back, handL, handR, footL, footR, ground }
