# 斗鱼扫码登录与 Cookie 续期

## 使用

- 手机/平板：我的 → 账号管理 → 斗鱼 → 扫码登录。
- Android TV：设置 → 斗鱼账号。
- 用另一台设备上的斗鱼 APP 扫描二维码，并在斗鱼 APP 内确认登录。
- 二维码过期后点击“刷新二维码”。手机端原有的手动 Cookie 配置入口仍保留。

确认登录后，客户端读取斗鱼 Passport 返回的 `LTP0` 与 `dy_did`，
换取直播播放 Cookie，并将三者保存到本机。重启应用后恢复这些数据；
读取斗鱼播放清晰度/地址前检查播放 Cookie 的有效期，过期时使用
Passport 凭据续期。续期失败时保留已有 Cookie；账号被撤销或续期凭据
本身失效后，需要再次扫码。退出登录会清除三项数据，并使进行中的续期失效。

扫码会话直接请求斗鱼的 HTTPS 接口，限制跳转域名并支持取消，
不依赖 WebView。登录与续期请求不输出敏感 HTTP 日志，
本地存储日志不输出斗鱼 Cookie 或续期凭据。

## 断流恢复

斗鱼播放结束或报错时重新获取当前清晰度的播放地址，再打开新的播放列表。
一次只允许一个恢复任务，失败后沿用原有重试/切换线路行为，
并用 30 秒冷却避免反复请求。切换房间、清晰度或退出页面后不应用旧恢复结果。
这不保证所有网络、平台或账号原因造成的断流均可避免。

## 界面预览

以下为实际 Flutter 页面在 Widget Test 中渲染的界面。
二维码使用 `example.invalid` 的示例数据，不是可用的登录码。

手机/平板：

![手机斗鱼扫码登录](images/douyu-qr-mobile.png)

Android TV（可用遥控器选择返回、刷新、退出）：

![电视斗鱼扫码登录](images/douyu-qr-tv.png)

## 验证

```sh
cd simple_live_app
flutter test test/version_parsing_test.dart test/douyu_persistence_test.dart
cd ../simple_live_tv_app
flutter test test/douyu_login_test.dart
```

测试使用模拟的斗鱼响应和临时 Hive 数据目录，覆盖扫码状态、HttpOnly
续期凭据、过期二维码、刷新失败、退出与刷新竞争、重启后的数据恢复、
敏感日志以及带构建后缀的版本号。

Android 14 小米平板验证过基于 v1.8.14 的本地构建可启动并显示斗鱼直播。
最新 dev 上的改动另行执行上述自动化测试与静态分析。
真实账号扫码确认、iOS 真机登录以及长时间断流恢复仍需维护者复核。
