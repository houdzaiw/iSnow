import Flutter
import UIKit

public class VolumeControllerPlugin: NSObject, FlutterPlugin {
  private let volumeController = VolumeController()

  public static func register(with registrar: FlutterPluginRegistrar) {
    // Method Channel
    let methodChannel = FlutterMethodChannel(
      name: ChannelName.methodChannel, binaryMessenger: registrar.messenger())
    let instance = VolumeControllerPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    // Volume Listener Event Channel
    let eventChannel: FlutterEventChannel = FlutterEventChannel(
      name: ChannelName.eventChannel,
      binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(VolumeListener())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case MethodName.getVolume:
      let volume = volumeController.getVolume()
      result(volume)
    case MethodName.setVolume:
      let arg = call.arguments as? [String: Any]
      let volume = arg?[MethodArgument.volume] as? Double
      let showSystemUI = arg?[MethodArgument.showSystemUI] as? Bool

      guard let volume = volume, let showSystemUI = showSystemUI else {
        result(FlutterError(code: "invalid_arguments", message: "Missing volume", details: nil))
        return
      }
      if volumeController.setVolume(volume: Float(volume), showSystemUI: showSystemUI) {
        result(nil)
      } else {
        result(FlutterError(code: "volume_unavailable", message: "System volume is unavailable", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
