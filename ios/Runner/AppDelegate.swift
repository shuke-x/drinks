import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appleUICapabilityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let capabilityChannel = FlutterMethodChannel(
      name: "tonight_drinks/apple_ui_capabilities",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    capabilityChannel.setMethodCallHandler { call, result in
      guard call.method == "supportsLiquidGlass" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 26.0, *) {
        result(true)
      } else {
        result(false)
      }
    }
    appleUICapabilityChannel = capabilityChannel

    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "AppleLiquidGlassButtonPlugin"
    ) {
      registrar.register(
        AppleLiquidGlassButtonFactory(messenger: registrar.messenger()),
        withId: "tonight_drinks/apple_liquid_glass_button"
      )
      registrar.register(
        AppleLiquidGlassTabBarFactory(messenger: registrar.messenger()),
        withId: "tonight_drinks/apple_liquid_glass_tab_bar"
      )
    }
  }
}

private final class AppleLiquidGlassTabBarFactory: NSObject, FlutterPlatformViewFactory {
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
    AppleLiquidGlassTabBarPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class AppleLiquidGlassTabBarPlatformView: NSObject,
  FlutterPlatformView, UITabBarDelegate
{
  private let tabBar: UITabBar
  private let channel: FlutterMethodChannel
  private var configuration: [String: Any]

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    tabBar = UITabBar(frame: frame)
    configuration = args as? [String: Any] ?? [:]
    channel = FlutterMethodChannel(
      name: "tonight_drinks/apple_liquid_glass_tab_bar/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    tabBar.delegate = self
    tabBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tabBar.itemPositioning = .fill
    tabBar.tintColor = .white
    tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.58)
    tabBar.overrideUserInterfaceStyle = .dark
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let values = call.arguments as? [String: Any] {
        self?.configuration = values
        self?.applyConfiguration()
      }
      result(nil)
    }
    applyConfiguration()
  }

  func view() -> UIView { tabBar }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard let index = tabBar.items?.firstIndex(of: item) else { return }
    channel.invokeMethod("select", arguments: index)
  }

  private func applyConfiguration() {
    let rawItems = configuration["items"] as? [[String: Any]] ?? []
    let items = rawItems.map { value in
      let image = (value["systemImageName"] as? String)
        .flatMap { UIImage(systemName: $0) }
      let selectedImage = (value["selectedSystemImageName"] as? String)
        .flatMap { UIImage(systemName: $0) }
      return UITabBarItem(
        title: value["label"] as? String,
        image: image,
        selectedImage: selectedImage
      )
    }
    tabBar.items = items
    let selectedIndex = (configuration["currentIndex"] as? NSNumber)?.intValue ?? 0
    if items.indices.contains(selectedIndex) {
      tabBar.selectedItem = items[selectedIndex]
    }
  }
}

private final class AppleLiquidGlassButtonFactory: NSObject, FlutterPlatformViewFactory {
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
    AppleLiquidGlassPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class AppleLiquidGlassPlatformView: NSObject, FlutterPlatformView {
  private let button: UIButton
  private let spreadLabel = UILabel()
  private let spreadImageView = UIImageView()
  private let channel: FlutterMethodChannel
  private var configuration: [String: Any]

  init(
    frame: CGRect,
    viewId: Int64,
    arguments: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    button = UIButton(type: .system)
    button.frame = frame
    button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    button.backgroundColor = .clear
    configuration = arguments as? [String: Any] ?? [:]
    channel = FlutterMethodChannel(
      name: "tonight_drinks/apple_liquid_glass_button/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    if configuration["spreadContent"] as? Bool == true {
      spreadLabel.translatesAutoresizingMaskIntoConstraints = false
      spreadLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
      spreadLabel.adjustsFontForContentSizeCategory = true
      spreadLabel.lineBreakMode = .byTruncatingTail
      spreadImageView.translatesAutoresizingMaskIntoConstraints = false
      spreadImageView.contentMode = .scaleAspectFit
      spreadImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
        pointSize: 15,
        weight: .semibold
      )
      button.addSubview(spreadLabel)
      button.addSubview(spreadImageView)
      NSLayoutConstraint.activate([
        spreadLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 14),
        spreadLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        spreadLabel.trailingAnchor.constraint(
          lessThanOrEqualTo: spreadImageView.leadingAnchor,
          constant: -8
        ),
        spreadImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -14),
        spreadImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        spreadImageView.widthAnchor.constraint(equalToConstant: 18),
        spreadImageView.heightAnchor.constraint(equalToConstant: 18),
      ])
    }

    button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let values = call.arguments as? [String: Any] {
        self?.configuration = values
        self?.applyConfiguration()
      }
      result(nil)
    }
    applyConfiguration()
  }

  func view() -> UIView { button }

  @objc private func didTap() {
    channel.invokeMethod("tap", arguments: nil)
  }

  private func applyConfiguration() {
    let label = configuration["label"] as? String
    let imageName = configuration["systemImageName"] as? String
    let semanticLabel = configuration["semanticLabel"] as? String
    let enabled = configuration["enabled"] as? Bool ?? true
    let prominent = configuration["prominent"] as? Bool ?? false
    let imageTrailing = configuration["imageTrailing"] as? Bool ?? false
    let spreadContent = configuration["spreadContent"] as? Bool ?? false
    let imagePadding = (configuration["imagePadding"] as? NSNumber)?.doubleValue ?? 8
    let fontSize = (configuration["fontSize"] as? NSNumber)?.doubleValue ?? 13.5
    let foreground = color(from: configuration["foregroundColor"])
    let background = color(from: configuration["backgroundColor"])

    button.isEnabled = enabled
    button.contentHorizontalAlignment = .center
    button.accessibilityLabel = semanticLabel ?? label
    button.accessibilityTraits = enabled ? [.button] : [.button, .notEnabled]
    spreadLabel.isHidden = !spreadContent
    spreadImageView.isHidden = !spreadContent
    spreadLabel.text = spreadContent ? label : nil
    spreadLabel.textColor = foreground
    spreadImageView.image = spreadContent
      ? imageName.flatMap { UIImage(systemName: $0) }
      : nil
    spreadImageView.tintColor = foreground

    if #available(iOS 26.0, *) {
      var glass = prominent
        ? UIButton.Configuration.prominentGlass()
        : UIButton.Configuration.glass()
      glass.title = spreadContent ? nil : label
      glass.image = spreadContent ? nil : imageName.flatMap { UIImage(systemName: $0) }
      glass.imagePlacement = imageTrailing ? .trailing : .leading
      glass.imagePadding = imagePadding
      glass.baseForegroundColor = foreground
      if configuration["backgroundColor"] != nil {
        glass.baseBackgroundColor = background
      }
      glass.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = (incoming.font ?? UIFont.systemFont(ofSize: fontSize))
          .withSize(fontSize)
        return outgoing
      }
      glass.cornerStyle = .capsule
      button.configuration = glass
      button.backgroundColor = .clear
      button.layer.borderWidth = 0
    } else if #available(iOS 15.0, *) {
      var fallback = UIButton.Configuration.gray()
      fallback.title = spreadContent ? nil : label
      fallback.image = spreadContent ? nil : imageName.flatMap { UIImage(systemName: $0) }
      fallback.imagePlacement = imageTrailing ? .trailing : .leading
      fallback.imagePadding = imagePadding
      fallback.baseForegroundColor = foreground
      if configuration["backgroundColor"] != nil {
        fallback.baseBackgroundColor = background
      }
      fallback.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = (incoming.font ?? UIFont.systemFont(ofSize: fontSize))
          .withSize(fontSize)
        return outgoing
      }
      fallback.cornerStyle = .capsule
      button.configuration = fallback
    } else {
      button.setTitle(label, for: .normal)
      button.setImage(imageName.flatMap { UIImage(systemName: $0) }, for: .normal)
      button.tintColor = foreground
      button.setTitleColor(foreground, for: .normal)
      button.titleLabel?.font = button.titleLabel?.font.withSize(fontSize)
      button.backgroundColor = configuration["backgroundColor"] != nil
        ? background
        : UIAccessibility.isReduceTransparencyEnabled
        ? UIColor(white: 0.20, alpha: 1)
        : UIColor(white: 1, alpha: 0.12)
      button.layer.cornerRadius = min(button.bounds.width, button.bounds.height) / 2
      button.layer.borderWidth = 1 / UIScreen.main.scale
      button.layer.borderColor = UIColor(white: 1, alpha: 0.22).cgColor
    }
  }

  private func color(from value: Any?) -> UIColor {
    let argb = (value as? NSNumber)?.uint32Value ?? 0xFFFFFFFF
    return UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }
}
