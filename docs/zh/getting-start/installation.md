# 安装
只保证Android, Linux和Windows可用性

请到Releases下载最新版本，iOS请到上游或者action下载体验
## 选择安装方式

| 系统                     | 包名                            | 适用场景          |
|--------------------------|---------------------------------|-------------------|
| Android 10+              | app-arm64-v8a-release.apk       | Android10+        |
| Windows 10+              | Slive-version-windows-setup.exe | Windows 10        |
| Windows 10+              | Slive-version-windows.msix      | Windows 10+       |
| Windows 10+              | Slive-version-windows.zip       | 便携版            |
| Linux                    | Slive-aarch64-linux.deb         | Linux arm64架构   |
| Linux                    | Slive-x86_64-linux.deb          | Linux x86_64架构  |
| Flatpak                  | Slive-aarch64.flatpak           | Linux arm64架构   |
| Flatpak                  | Slive-x86_64.flatpak            | Linux x86_64架构  |
| [Arch Linux](#ArchLinux) | 源码安装/bin包                  | Arch Linux x86_64 |

## ArchLinux
```bash
  yay -S slive
  yay -S slive-bin
```

## 便携版
```bash
  # 启动参数的用法
  # Windows_PowerShell
  .\slive.exe -p  #数据启动目录为 ./data_hive_ce
  .\slive.exe --portable #数据启动目录为 ./data_hive_ce
  .\slive.exe -h
```
- 在Slive应用根目录创建 data_hive_ce 文件夹，Slive会设置默认读写该文件夹数据