# 土豆视频 iPhone 版

原生 SwiftUI iPhone 工程，支持影片搜索、搜索历史、收藏文件夹、选集、在线播放和播放器触控操作。“我的收藏”位于搜索框下方；详情页可将整部电影或电视剧加入文件夹，再从收藏直接进入影片详情与选集。收藏保存在本机。画面与 Android 版保持一致，使用原小狗照片做图标和用户提供的白色小狗背景。应用内部有效期为首次打开后 36500 天，期限不在界面显示；此本地计时无法防止卸载重装或修改系统时间。最低系统为 iOS 16。

## GitHub Actions 生成 IPA

将本目录作为 GitHub 仓库根目录提交。每次推送会在 GitHub 的 macOS 机器上运行 `.github/workflows/build-ipa.yml`，编译 iPhone 设备版并上传 `PotatoVideo-unsigned-ipa` 构建产物。下载该 ZIP，解压后得到 `PotatoVideo-unsigned.ipa`。此 IPA 未签名，需由 iLoader 在导入时完成签名；苹果签名的有效期与应用内部的 36500 天限制无关。

当前 Windows 电脑上没有 Xcode，因此本地无法编译或验证 IPA。首次推送后应以 Actions 的构建结果为准。
