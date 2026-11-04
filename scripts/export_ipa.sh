#!/usr/bin/env bash
# 只从已有归档导出 .ipa(不重新编译)。归档由 scripts/build_ipa.sh 生成。
# 前提:Xcode → Settings → Accounts 已登录拥有 J95TRWHWYM 团队的 Apple ID,
#       -allowProvisioningUpdates 会用它自动申请 Apple Distribution 证书与 App Store profile。
set -euo pipefail
cd "$(dirname "$0")/.."

archive=build/ios/archive/Runner.xcarchive
[[ -d "$archive" ]] || { echo "找不到 $archive,先跑 scripts/build_ipa.sh"; exit 1; }

xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates

echo
echo "产物:"
ls -1 build/ios/ipa/*.ipa
echo "上传:用 Transporter.app 拖入上面的 .ipa。"
