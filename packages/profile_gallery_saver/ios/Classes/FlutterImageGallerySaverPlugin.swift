import Flutter
import UIKit

public class FlutterImageGallerySaverPlugin: NSObject, FlutterPlugin {
  var result: FlutterResult?;

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dev.knottx.flutter_image_gallery_saver", binaryMessenger: registrar.messenger())
    let instance = FlutterImageGallerySaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.result = result
    switch call.method {
      case "save_image":
        if let arguments = call.arguments as? [String: Any],
          let imageData = (arguments["image_bytes"] as? FlutterStandardTypedData)?.data,
          let image = UIImage(data: imageData) { 
            saveImage(image)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid Arguments", details: nil))
        }

      case "save_file":
        if let arguments = call.arguments as? [String: Any],
          let filePath = arguments["file_path"] as? String { 
            if isImageFile(filePath), let image = UIImage(contentsOfFile: filePath) {
              saveImage(image)
            } else if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) {
              saveVideo(filePath)
            } else {
              result(FlutterError(code: "INVALID_FILE", message: "Invalid File", details: nil))
            }
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid Arguments", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
    }
  }

  func isImageFile(_ filePath: String) -> Bool {
    let ext = (filePath as NSString).pathExtension.lowercased()
    let allowedExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic"]
    return allowedExtensions.contains(ext)
  }

  func saveImage(_ image: UIImage) {
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingImage(image:error:contextInfo:)), nil)
  }

  @objc func didFinishSavingImage(image: UIImage, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
    if let error = error {
      self.result?(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
    } else {
      self.result?(nil)
    }
  }

  func saveVideo(_ filePath: String) {
    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, #selector(didFinishSavingVideo(videoPath:error:contextInfo:)), nil)
  }

  @objc func didFinishSavingVideo(videoPath: String, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
    if let error = error {
      self.result?(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
    } else {
      self.result?(nil)
    }
  }

}
