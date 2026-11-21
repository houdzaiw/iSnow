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
  The local view exposes an idempotent asynchronous `release()` that also waits
  for an in-flight initialization, and an optional `onError` callback. A loading
  fallback is not an animation completion. Android acknowledges cached-render
  release only after the worker has cleared it, matching the iOS handover order.
  `onCreated` exposes the controller while initialization is pending. The room
  player retains it across widget removal so its playback lease waits for native
  destruction. The player disables native autoplay, binds callbacks first, then
  starts explicitly from `onInit`; Android can otherwise emit its start event
  before the initialization reply reaches Dart.
- VAP targets Android API 23+, includes its process lifecycle dependency,
  stops video on disposal, and keeps native destruction acknowledgements alive
  after the Flutter view detaches. Android `stop` waits for decoder destruction
  (with a bounded failure reply), disarms automatic loop restart, and defers a
  lifecycle restart until the previous decoder is gone. The Dart controller
  coalesces stop calls, settles canceled playback after the native reply, and
  rejects late starts after stop/disposal. Timeouts report failure; an actual
  looping decoder's `onStart` cancels its completion deadline while startup
  remains bounded. Android receives the resolved legacy alpha
  layout (`videoMode` / `direction`); embedded VAP metadata remains authoritative.
  iOS retains Nady's metadata-based playback and native stop path; Android
  acceptance does not certify iOS release ordering.

The isolated Android decoder/lifecycle harness lives in
`tools/room_gift_native_acceptance/`. It imports these actual workspace sources
and forwards real native calls; it does not log in or send gift orders.

Each directory retains its upstream license. App-level analyzer rules exclude
vendored sources to avoid restyling third-party code; player compilation is
verified by Flutter tests and the Android APK build. API and application code
are still analyzed normally.
