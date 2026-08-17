import UIKit
import Flutter
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var artworkCache: [String: MPMediaItemArtwork] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    configureAudioSession()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 通过 registrar 获取 messenger，兼容隐式引擎的 bridge API
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NowPlaying") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "simple_live/now_playing",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "AppDelegate deallocated", details: nil))
        return
      }
      switch call.method {
      case "configure":
        self.configureAudioSession()
        result(nil)
      case "update":
        let args = call.arguments as? [String: Any] ?? [:]
        self.updateNowPlaying(args)
        result(nil)
      case "setPlaying":
        let args = call.arguments as? [String: Any] ?? [:]
        let playing = args["playing"] as? Bool ?? false
        self.setPlaying(playing)
        result(nil)
      case "clear":
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    setupRemoteCommands(channel)
  }

  /// 配置并激活音频会话，保证后台播放与系统媒体中心可用
  private func configureAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
    } catch {
      // 会话配置失败不阻塞应用启动
    }
  }

  /// 更新正在播放的直播信息到系统媒体中心（锁屏/控制中心/灵动岛）
  private func updateNowPlaying(_ args: [String: Any]) {
    let title = args["title"] as? String ?? ""
    let artist = args["artist"] as? String ?? ""
    let artworkUrl = args["artworkUrl"] as? String ?? ""
    let isLive = args["isLive"] as? Bool ?? true

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: artist,
      MPNowPlayingInfoPropertyIsLiveStream: isLive,
      MPNowPlayingInfoPropertyPlaybackRate: 1.0,
    ]
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info

    // 异步加载封面，失败则保持无封面状态
    guard !artworkUrl.isEmpty else { return }
    loadArtwork(artworkUrl) { artwork in
      guard let artwork = artwork else { return }
      var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
      updated[MPMediaItemPropertyArtwork] = artwork
      MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
    }
  }

  /// 同步播放/暂停状态
  private func setPlaying(_ playing: Bool) {
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
    info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  /// 远程控制（锁屏/耳机/控制中心的播放暂停按钮）回调到 Dart 侧
  private func setupRemoteCommands(_ channel: FlutterMethodChannel) {
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.addTarget { [weak channel] _ in
      channel?.invokeMethod("onRemoteCommand", arguments: "play")
      return .success
    }
    commandCenter.pauseCommand.addTarget { [weak channel] _ in
      channel?.invokeMethod("onRemoteCommand", arguments: "pause")
      return .success
    }
    commandCenter.stopCommand.addTarget { [weak channel] _ in
      channel?.invokeMethod("onRemoteCommand", arguments: "stop")
      return .success
    }
  }

  /// 下载封面并缓存为 MPMediaItemArtwork
  private func loadArtwork(_ urlString: String, completion: @escaping (MPMediaItemArtwork?) -> Void) {
    if let cached = artworkCache[urlString] {
      completion(cached)
      return
    }
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let data = data, let image = UIImage(data: data) else {
        DispatchQueue.main.async { completion(nil) }
        return
      }
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      self?.artworkCache[urlString] = artwork
      DispatchQueue.main.async { completion(artwork) }
    }.resume()
  }
}
