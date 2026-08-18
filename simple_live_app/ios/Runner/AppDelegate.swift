import UIKit
import Flutter
import AVFoundation
import ActivityKit

// Live Activity 属性类型（与 LiveActivityExtension 中同名定义，ActivityKit 按类型名匹配）
struct LiveStreamActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var online: Int
        var isLive: Bool
    }

    var title: String
    var artist: String
    var thumbnailUrl: String
    var isLive: Bool
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    // Live Activity 属性类型仅 iOS 16.1+ 可用，用 Any? 存储，使用时在 #available 内转换
    private var liveActivityStore: Any?

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

        guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SliveNative") else {
            return
        }
        let messenger = registrar.messenger()

        setupLiveActivityChannel(messenger)
        registrar.register(
            NativeGlassTabBarViewFactory(messenger: messenger),
            withId: "simple_live/native_glass_tab_bar"
        )
    }

    // MARK: - 音频会话（后台播放）

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            // 会话配置失败不阻塞应用启动
        }
    }

    // MARK: - Live Activity（灵动岛，点击直接回 App）

    private func setupLiveActivityChannel(_ messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "simple_live/live_activity", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(code: "unavailable", message: "AppDelegate deallocated", details: nil))
                return
            }
            switch call.method {
            case "start":
                self.startLiveActivity(call.arguments as? [String: Any] ?? [:])
                result(nil)
            case "update":
                self.updateLiveActivity(call.arguments as? [String: Any] ?? [:])
                result(nil)
            case "end":
                self.endLiveActivity()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startLiveActivity(_ args: [String: Any]) {
        guard #available(iOS 16.2, *) else { return }
        let title = args["title"] as? String ?? ""
        let artist = args["artist"] as? String ?? ""
        let thumbnailUrl = args["thumbnailUrl"] as? String ?? ""
        let isLive = args["isLive"] as? Bool ?? true
        let online = args["online"] as? Int ?? 0

        // 已有活动则只更新状态，避免在灵动岛堆积多个活动
        if let activity = liveActivityStore as? Activity<LiveStreamActivityAttributes> {
            let state = LiveStreamActivityAttributes.ContentState(online: online, isLive: isLive)
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }
        let attributes = LiveStreamActivityAttributes(
            title: title,
            artist: artist,
            thumbnailUrl: thumbnailUrl,
            isLive: isLive
        )
        let state = LiveStreamActivityAttributes.ContentState(online: online, isLive: isLive)
        do {
            liveActivityStore = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
        } catch {
            // 启动失败静默处理
        }
    }

    private func updateLiveActivity(_ args: [String: Any]) {
        guard #available(iOS 16.2, *) else { return }
        guard let activity = liveActivityStore as? Activity<LiveStreamActivityAttributes> else { return }
        let online = args["online"] as? Int ?? 0
        let isLive = args["isLive"] as? Bool ?? true
        let state = LiveStreamActivityAttributes.ContentState(online: online, isLive: isLive)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    private func endLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        guard let activity = liveActivityStore as? Activity<LiveStreamActivityAttributes> else { return }
        liveActivityStore = nil
        let state = LiveStreamActivityAttributes.ContentState(online: 0, isLive: false)
        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }
}

// MARK: - 原生 iOS 26 液态玻璃底部导航（平台视图）

class NativeGlassTabBarViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeGlassTabBarView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeGlassTabBarView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let channel: FlutterMethodChannel
    private var itemButtons: [UIButton] = []
    private let selectedColor = UIColor(red: 52 / 255.0, green: 152 / 255.0, blue: 219 / 255.0, alpha: 1.0)

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "simple_live/native_glass_tab", binaryMessenger: messenger)
        super.init()

        container.frame = frame
        container.backgroundColor = .clear

        var tabs: [[String: Any]] = []
        if let args = args as? [String: Any], let list = args["tabs"] as? [[String: Any]] {
            tabs = list
        }
        buildUI(tabs: tabs)

        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "setIndex",
               let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                self?.setSelected(index: index)
            }
            result(nil)
        }
    }

    func view() -> UIView {
        return container
    }

    private func buildUI(tabs: [[String: Any]]) {
        let pill = UIView(frame: CGRect(x: 16, y: 8, width: max(container.bounds.width - 32, 0), height: 56))
        pill.layer.cornerRadius = 28
        pill.layer.cornerCurve = .continuous
        pill.clipsToBounds = true
        // 半透明主题着色 + 高光描边兜底：即使平台视图内的玻璃材质未生效，
        // 底部栏也呈现清晰的玻璃面板观感
        pill.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.22)
        pill.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        pill.layer.borderWidth = 1.0
        if #available(iOS 26.0, *) {
            // iOS 26 原生液态玻璃：UIGlassEffect 由 UIVisualEffectView 承载
            let glassView = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
            glassView.frame = pill.bounds
            glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pill.addSubview(glassView)
        } else {
            pill.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.85)
        }
        // 顶部高光条：模拟液态玻璃的镜面反射边缘
        let highlight = UIView(frame: CGRect(x: 0, y: 0, width: pill.bounds.width, height: 1.5))
        highlight.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        highlight.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        pill.addSubview(highlight)
        container.addSubview(pill)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
        ])

        for (i, tab) in tabs.enumerated() {
            let iconName = tab["icon"] as? String ?? "circle"
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: iconName), for: .normal)
            button.tag = i
            button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 22
            stack.addArrangedSubview(button)
            itemButtons.append(button)
        }
        setSelected(index: 0)
    }

    @objc private func itemTapped(_ sender: UIButton) {
        let index = sender.tag
        setSelected(index: index)
        channel.invokeMethod("onTabSelected", arguments: ["index": index])
    }

    private func setSelected(index: Int) {
        for (i, button) in itemButtons.enumerated() {
            let selected = (i == index)
            button.tintColor = selected ? selectedColor : UIColor.secondaryLabel
            button.backgroundColor = selected ? UIColor.secondarySystemFill : .clear
        }
    }
}
