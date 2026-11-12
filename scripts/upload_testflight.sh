#!/usr/bin/env bash
# 把 scripts/build_ipa.sh 生成的归档用 App Store Connect API key 云签名并直接上传到
# App Store Connect(TestFlight)。不依赖 Xcode 的登录态。
#
# 配置:~/.config/cofit-release/config.json  { "keyId": "...", "issuerId": "..." }
#       私钥在 ~/.appstoreconnect/private_keys/AuthKey_<keyId>.p8(与 GeoGhost 共用同一团队 J95TRWHWYM 的发布 key)。
# 用法:scripts/build_ipa.sh && scripts/upload_testflight.sh
set -euo pipefail
cd "$(dirname "$0")/.."

archive=build/ios/archive/Runner.xcarchive
[[ -d "$archive" ]] || { echo "找不到 $archive,先跑 scripts/build_ipa.sh"; exit 1; }

config=${COFIT_ASC_CONFIG:-$HOME/.config/cofit-release/config.json}
[[ -f "$config" ]] || { echo "缺少 $config(keyId / issuerId),见 docs/release/app_store_connect_testflight.md"; exit 1; }
key_id=$(plutil -extract keyId raw "$config")
issuer_id=$(plutil -extract issuerId raw "$config")
key_path=$HOME/.appstoreconnect/private_keys/AuthKey_$key_id.p8
[[ -f "$key_path" ]] || { echo "缺少私钥 $key_path"; exit 1; }

# 与 ios/ExportOptions.plist 唯一区别:destination = upload。
upload_plist=build/ios/ExportOptionsUpload.plist
cp ios/ExportOptions.plist "$upload_plist"
plutil -replace destination -string upload "$upload_plist"

xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist "$upload_plist" \
  -exportPath build/ios/upload \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$key_path" \
  -authenticationKeyID "$key_id" \
  -authenticationKeyIssuerID "$issuer_id"

echo
echo "已上传。App Store Connect → TestFlight 处理完(10–30 分钟)后出现新 build。"
