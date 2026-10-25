import AVFoundation
import Flutter
import Foundation
import MediaPlayer
import UIKit

public class VolumeListener: NSObject, FlutterStreamHandler {
  private let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
  private var eventSink: FlutterEventSink?
  private var isObserving: Bool = false
  private let volumeKey: String = "outputVolume"

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let args = arguments as! [String: Any]
    let fetchInitialVolume = args[EventArgument.fetchInitialVolume] as! Bool

    self.eventSink = events
    registerVolumeObserver()

    if fetchInitialVolume {
      events(audioSession.outputVolume)
    }

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    removeVolumeObserver()

    return nil
  }

  private func registerVolumeObserver() {
    // Agora owns the audio session category and activation lifecycle.
    if !isObserving {
      audioSession.addObserver(
        self,
        forKeyPath: volumeKey,
        options: .new,
        context: nil)
      isObserving = true
    }
  }

  private func removeVolumeObserver() {
    if isObserving {
      audioSession.removeObserver(self, forKeyPath: volumeKey)
      isObserving = false
    }
  }

  deinit {
    removeVolumeObserver()
  }

  override public func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == volumeKey else {
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.isObserving else { return }
      self.eventSink?(self.audioSession.outputVolume)
    }
  }
}
