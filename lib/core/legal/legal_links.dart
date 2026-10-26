import 'package:url_launcher/url_launcher.dart';

/// 法律文档地址(GitHub Pages 托管,源文件在 docs/legal/,由 GitSpec 工作流发布;
/// GitSpec 的 URL 规则:`docs/legal/privacy.md` → `/co-fit/docs-legal-privacy`)。
abstract class LegalLinks {
  static final privacyPolicy = Uri.parse(
    'https://passerbo.github.io/co-fit/docs-legal-privacy',
  );
  static final termsOfService = Uri.parse(
    'https://passerbo.github.io/co-fit/docs-legal-terms',
  );

  /// 外开系统浏览器;返回 false 表示无法打开(调用方可 toast)。
  static Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
