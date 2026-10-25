# Local compatibility changes

Vendored from volume_controller 3.0.0 (Nady's version); upstream LICENSE retained.

- Await all Dart writes and listener cancellation.
- Complete Android/iOS method results after volume writes (upstream omitted the result).
- iOS reads/listeners never change AVAudioSession category or activation; Agora owns it.
- iOS KVO delivers on the main queue and writes report unavailable MPVolumeView sliders.
- No SDK upgrade, extra permissions or automatic system-volume reset.
