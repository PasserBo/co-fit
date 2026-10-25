# 品牌素材源文件

- `app_icon.svg` → `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`(全部尺寸按 Contents.json 用 `rsvg-convert -w N -h N` 生成)
- `launch_figure.svg` → `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png`(120×160 / 240×320 / 360×480);storyboard 底色 gray-900 `#181B22`

2026-10-26 临时版(bob 小人 + 两张斜卡),正式图标出来后替换这两个 SVG 重新导出即可。
