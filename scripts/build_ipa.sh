#!/usr/bin/env bash
# 打 App Store / TestFlight 用的 .ipa。
# 必须带 .env(ABLY_API_KEY / ABLY_CLIENT_ID_PREFIX),否则包里没有 Ably key,房间永远「未配置」。
# 用法:scripts/build_ipa.sh            # 用 pubspec.yaml 的 version
#       scripts/build_ipa.sh 1.0.0 3    # 覆盖 build-name / build-number
set -euo pipefail
cd "$(dirname "$0")/.."

# 规则(CLAUDE.md):用于提交的 build 必须从 main 打包——在 main 上、工作区干净、
# 且与 origin/main 一致。否则线上版本会包含 main 没有的代码(1.0.0 (4) 的教训)。
branch="$(git rev-parse --abbrev-ref HEAD)"
[[ "$branch" == "main" ]] || { echo "当前分支是 $branch。提交用的 build 必须从 main 打包:先把分支合进 main。"; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "工作区有未提交的改动。请先提交或清理,再从 main 打包。"; exit 1; }
git fetch --quiet origin main || { echo "无法连接远端确认 origin/main,已停止。"; exit 1; }
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || { echo "本地 main 与 origin/main 不一致。请先 push(或 pull)后再打包。"; exit 1; }

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
