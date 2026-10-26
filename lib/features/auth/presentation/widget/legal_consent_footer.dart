import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/legal/legal_links.dart';
import '../../../../core/theme/cofit_colors.dart';

/// 登录页底部「登录即表示同意」文案,两处可点链接外开浏览器。纯展示。
/// Stateful 只为持有并 dispose TapGestureRecognizer。
class LegalConsentFooter extends StatefulWidget {
  const LegalConsentFooter({super.key, this.onOpen});

  /// 测试注入;默认 [LegalLinks.open]。
  final Future<bool> Function(Uri uri)? onOpen;

  @override
  State<LegalConsentFooter> createState() => _LegalConsentFooterState();
}

class _LegalConsentFooterState extends State<LegalConsentFooter> {
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () =>
        (widget.onOpen ?? LegalLinks.open)(LegalLinks.termsOfService);
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () =>
        (widget.onOpen ?? LegalLinks.open)(LegalLinks.privacyPolicy);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final base = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.textDisabled);
    final link = base?.copyWith(
      color: colors.textSecondary,
      decoration: TextDecoration.underline,
      decorationColor: colors.textSecondary,
    );

    return Text.rich(
      TextSpan(
        text: '登录即表示同意',
        style: base,
        children: [
          TextSpan(text: '《用户协议》', style: link, recognizer: _termsTap),
          const TextSpan(text: '与'),
          TextSpan(text: '《隐私政策》', style: link, recognizer: _privacyTap),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
