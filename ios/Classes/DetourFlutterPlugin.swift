import Flutter
import UIKit

public class DetourFlutterPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    private var config: DetourConfig?
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "detour_flutter_plugin",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "detour_flutter_plugin/links",
            binaryMessenger: registrar.messenger()
        )
        let instance = DetourFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - FlutterApplicationLifeCycleDelegate

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]
    ) -> Bool {
        self.launchOptions = launchOptions
        return true
    }

    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard let config = self.config, let sink = self.eventSink else { return false }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await Detour.shared.processLink(url, config: config)
            sink(self.detourResultToMap(result))
        }
        return true
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard let config = self.config,
              let sink = self.eventSink,
              let url = userActivity.webpageURL else { return false }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await Detour.shared.processLink(url, config: config)
            sink(self.detourResultToMap(result))
        }
        return true
    }

    // MARK: - FlutterMethodCallHandler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            guard let args = call.arguments as? [String: Any],
                  let config = configFromArgs(args) else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing apiKey or appID", details: nil))
                return
            }
            self.config = config
            result(nil)

        case "resolveInitialLink":
            guard let config = self.config else {
                result(FlutterError(code: "NOT_CONFIGURED", message: "Call configure() first", details: nil))
                return
            }
            let launchOpts = self.launchOptions
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                Detour.shared.resolveInitialLink(config: config, launchOptions: launchOpts) { r in
                    result(self.detourResultToMap(r))
                }
            }

        case "processLink":
            guard let config = self.config else {
                result(FlutterError(code: "NOT_CONFIGURED", message: "Call configure() first", details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                  let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "url is required", details: nil))
                return
            }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let r = await Detour.shared.processLink(url, config: config)
                result(self.detourResultToMap(r))
            }

        case "resetSession":
            let args = call.arguments as? [String: Any]
            let allowDeferredRetry = args?["allowDeferredRetry"] as? Bool ?? false
            Task { @MainActor in
                Detour.shared.resetSession(allowDeferredRetry: allowDeferredRetry)
            }
            result(nil)

        case "mountAnalytics":
            guard let config = self.config else {
                result(FlutterError(code: "NOT_CONFIGURED", message: "Call configure() first", details: nil))
                return
            }
            Task { @MainActor in
                Detour.shared.mountAnalytics(config: config)
            }
            result(nil)

        case "unmountAnalytics":
            Task { @MainActor in
                Detour.shared.unmountAnalytics()
            }
            result(nil)

        case "logEvent":
            guard let args = call.arguments as? [String: Any],
                  let eventName = args["eventName"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "eventName is required", details: nil))
                return
            }
            let data = args["data"] as? [String: Any]
            Task { @MainActor in
                DetourAnalytics.logEvent(eventName, data: data)
            }
            result(nil)

        case "logRetention":
            guard let args = call.arguments as? [String: Any],
                  let eventName = args["eventName"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "eventName is required", details: nil))
                return
            }
            Task { @MainActor in
                DetourAnalytics.logRetention(eventName)
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helpers

    private func detourResultToMap(_ r: DetourResult) -> [String: Any?] {
        var map: [String: Any?] = ["processed": r.processed]
        if let link = r.link {
            map["link"] = [
                "url": link.url,
                "route": link.route,
                "pathname": link.pathname,
                "params": link.params,
                "type": link.type.rawValue,
            ] as [String: Any]
        } else {
            map["link"] = nil
        }
        return map
    }

    private func configFromArgs(_ args: [String: Any]) -> DetourConfig? {
        guard let apiKey = args["apiKey"] as? String,
              let appID = args["appID"] as? String else { return nil }
        let shouldUseClipboard = args["shouldUseClipboard"] as? Bool ?? true
        let modeStr = args["linkProcessingMode"] as? String ?? "all"
        let mode: LinkProcessingMode
        switch modeStr {
        case "web-only": mode = .webOnly
        case "deferred-only": mode = .deferredOnly
        default: mode = .all
        }
        return DetourConfig(
            apiKey: apiKey,
            appID: appID,
            shouldUseClipboard: shouldUseClipboard,
            linkProcessingMode: mode
        )
    }
}

// MARK: - FlutterStreamHandler

extension DetourFlutterPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
