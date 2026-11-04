#!/usr/bin/env bash
# 打 App Store / TestFlight 用的 .ipa。
# 必须带 .env(ABLY_API_KEY / ABLY_CLIENT_ID_PREFIX),否则包里没有 Ably key,房间永远「未配置」。
# 用法:scripts/build_ipa.sh            # 用 pubspec.yaml 的 version
#       scripts/build_ipa.sh 1.0.0 3    # 覆盖 build-name / build-number
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo "缺少 .env(含 ABLY_API_KEY),见 CLAUDE.md"; exit 1; }

extra=()
if [[ $# -ge 2 ]]; then
  extra+=(--build-name="$1" --build-number="$2")
fi

# 前提:Xcode → Settings → Accounts 已登录拥有 J95TRWHWYM 团队的 Apple ID,
# 否则导出 ipa 时报 "No Accounts / No signing certificate iOS Distribution"。
# 归档成功但导出失败时,登录账号后只需跑 scripts/export_ipa.sh,不用重新编译。
fvm flutter build ipa --release \
  --dart-define-from-file=.env \
  --export-options-plist=ios/ExportOptions.plist \
  "${extra[@]}"

echo
echo "产物:"
ls -1 build/ios/ipa/*.ipa
echo "上传:用 Transporter.app 拖入上面的 .ipa,或 open build/ios/archive/Runner.xcarchive 走 Organizer。"
