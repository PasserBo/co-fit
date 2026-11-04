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

fvm flutter build ipa --release \
  --dart-define-from-file=.env \
  --export-method app-store \
  "${extra[@]}"

echo
echo "产物:"
ls -1 build/ios/ipa/*.ipa
echo "上传:用 Transporter.app 拖入上面的 .ipa,或 open build/ios/archive/Runner.xcarchive 走 Organizer。"
