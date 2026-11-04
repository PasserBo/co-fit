# 品牌素材源文件

- `app_icon.svg` → `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`(全部尺寸按 Contents.json 用 `rsvg-convert -w N -h N` 生成)
- `launch_figure.svg` → `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png`(120×160 / 240×320 / 360×480);storyboard 底色 gray-900 `#181B22`

2026-11-05 图标换成豆豆形象(几何直接取自 [avatar_bean_spec.md](../avatar_bean_spec.md) §1:蛋体 path、四肢圆角矩形、lime@90 描边、两点眼)+ 两张斜卡,深底 + lime 径向微光。改形象规格时同步改 `app_icon.svg` 里的几何。
`launch_figure.svg` 同日换成豆豆(同一套几何,scale 1.5,背景透明,四肢缝描边用 storyboard 底色 gray-900);重导出:`for k in 1 2 3; do rsvg-convert -w $((120*k)) -h $((160*k)) docs/brand/launch_figure.svg -o ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$([ $k -gt 1 ] && echo @${k}x).png; done`。

一键重导出全部图标尺寸(按 Contents.json):

```bash
python3 -c "import json,subprocess;[subprocess.run(['rsvg-convert','-w',str(int(float(i['size'].split('x')[0])*int(i['scale'][0]))),'-h',str(int(float(i['size'].split('x')[0])*int(i['scale'][0]))),'docs/brand/app_icon.svg','-o','ios/Runner/Assets.xcassets/AppIcon.appiconset/'+i['filename']],check=True) for i in json.load(open('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'))['images']]"
```

导出后用 `sips -g hasAlpha` 确认 1024 图无 alpha(App Store 要求)。
