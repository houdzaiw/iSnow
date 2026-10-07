# Room Gift Players

These are minimal, portable copies of the players already used by the local
Nady reference project. They do not depend on another developer's pub cache or
absolute filesystem paths. Only runtime sources and licenses are included.

| Directory | Upstream | Nady Revision / Version |
| --- | --- | --- |
| `room_svga` | https://github.com/svga/SVGAPlayer-Flutter | `f2e2ecaa6e7745b3bb1034bce7d4ed1682487b87`, 2.2.0+1 |
| `room_pag` | https://github.com/libpag/pag-flutter | `5d149e54ea4ec5a6beb1ddcd331b388ddd8f4551`, 1.0.9+flutter3.29 |
| `room_vap` | https://github.com/Astra1427/flutter_vap_plus | Nady native fork 1.2.10 |

Compatibility changes:

- SVGA uses protobuf 6, matching Centrifuge. Removed unused legacy
  `createRepeated` factories, which call a removed protobuf constructor.
  Decoding a Nady SVGA fixture is covered by the app's tests.
- PAG retains Nady's Flutter 3.29-compatible Android/iOS runtime. The unused
  OHOS registration is omitted.
- VAP targets Android API 23+, includes its process lifecycle dependency,
  stops video and cancels coroutines on disposal, and completes pending Dart
  playback futures when disposed. Android receives the resolved legacy alpha
  layout (`videoMode` / `direction`); embedded VAP metadata remains authoritative.
  iOS retains Nady's metadata-based playback path.

Each directory retains its upstream license. App-level analyzer rules exclude
vendored sources to avoid restyling third-party code; player compilation is
verified by Flutter tests and the Android APK build. API and application code
are still analyzed normally.
