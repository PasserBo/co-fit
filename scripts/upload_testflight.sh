#!/usr/bin/env bash
# 把 scripts/build_ipa.sh 生成的归档直接上传到 App Store Connect(TestFlight)。
# 不需要 API key / 应用专用密码:xcodebuild 用 Xcode → Settings → Accounts 里登录的
# Apple ID(需拥有 J95TRWHWYM 团队)完成签名与上传,等价于 Organizer 的 Upload。
# 用法:scripts/build_ipa.sh && scripts/upload_testflight.sh
set -euo pipefail
cd "$(dirname "$0")/.."

archive=build/ios/archive/Runner.xcarchive
[[ -d "$archive" ]] || { echo "找不到 $archive,先跑 scripts/build_ipa.sh"; exit 1; }

# 与 ios/ExportOptions.plist 唯一区别:destination = upload。
upload_plist=build/ios/ExportOptionsUpload.plist
cp ios/ExportOptions.plist "$upload_plist"
plutil -replace destination -string upload "$upload_plist"

xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist "$upload_plist" \
  -exportPath build/ios/upload \
  -allowProvisioningUpdates

echo
echo "已上传。App Store Connect → TestFlight 处理完(10–30 分钟)后出现新 build。"
