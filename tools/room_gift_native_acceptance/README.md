# Android room-player acceptance

This harness compiles the workspace's **actual** room player and full-screen
layer through a source symlink in a temporary Flutter project. It installs a
separate `com.isnow.qa.room_gift_native_acceptance` package. It does not import
the application's startup, HTTP API, authentication, Socket, Agora, IM or wallet
modules, and cannot submit gift orders. It does not replace or clear iSnow.

```sh
python3 tools/room_gift_native_acceptance/run.py --device emulator-5554
```

The generated project defaults to `/tmp/isnow_room_gift_native_acceptance`.
Native plugins are built directly from the workspace; the channel recorder
forwards each original message and callback to the real platform delegate.
Race tests deliberately delay delivery of authentic PAG initialization and VAP
configuration replies; they do not fabricate native results. Playback screenshots
are checked for visible fixture pixels outside the debug banner. A transparent
first frame is not accepted as visual evidence, and each run gets a new evidence
directory so failed captures remain available.
Continuous rendering is explicitly enabled (`fullyLive`); an integration test's
default pump policy must not freeze a Dart animation at its transparent first
frame. The original repository SVGA fixture is additionally checked unchanged.
Use `--case 'repository SVGA'` to run only that check.
Multiple literal name fragments can be separated with semicolons, for example
`--case 'actual Android;local visibility;prepared prize;local asset'`.

Use `--case combination` for the five scheduling-combination checks: vehicle
start gating with each completion order, PAG-to-numeric and numeric-to-PAG
handover, and Keep during pending PAG initialization followed by a fresh task.
They use the production event manager, full-screen layer, players and shared
playback barrier. The numeric adapter deliberately holds a looping decoder
fixture for handover inspection; it is not a replacement for the shipping
numeric widget or proof that shipping numbers should loop. The entrance track
is observed as manager state in this native adapter, not rendered as a fake
production track. The actual entrance, avatar-frame/mic and numeric widgets are
covered in `test/room_visual_combinations_test.dart`, including 320/375/430 widths,
temporary expiry, failed resources and late results after a seat change.
The new gates delay delivery of authentic native release/stop replies; trace
entries distinguish native destruction acknowledgement from delivery to Dart.
No successful platform reply is fabricated.

The expanded suite additionally mounts the production barrage background and
foreground together, replaces a PAG view while native initialization is pending,
checks prepared-prize handover and clears full-screen tasks through the production
event manager. The 23 shipping lucky-number videos and three bubble videos are
copied unchanged and rendered with explicitly local QA text/avatar replacements.
These do not fabricate a gift order or a server broadcast. VAP startup checks
allow view creation plus the controller's existing 20-second startup watchdog;
the production watchdog and pixel visibility checks are not relaxed.

A private, permission-free QA channel moves its own Android task to the background.
After the real native `onStop`, the host driver waits 800ms and brings only this
QA task back with ADB. This avoids Android's background activity launch restriction.
Native pause/stop/resume logs and Flutter
paused/resumed events must both be observed; losing window focus is insufficient.
The QA lifecycle adapter forwards visibility to the production event
manager; it is not the main app's Socket/Keep binding. The native trace now includes
timestamps so focus-only transitions cannot be reported as a paused/resumed test.
After widget removal, release checks use the real native stop reply: the removed
view may no longer receive `onDestroy`. The separate direct-controller test still
requires that callback before stop completes.
The QA app remains installed/running after a test, and retains a temporary report
and original PNG samples in its own cache, so a host transport failure cannot
silently erase the evidence. The normal host export remains the primary report.

On physical SurfaceView devices, an initial empty Flutter scene must mount before
converting the surface for screenshots, followed by the native scene. The harness
relies on this Flutter SDK's per-test teardown to revert conversion; it does not
convert in `setUpAll`. This avoids the PLL110 launch-splash stall observed when
conversion happened before the first Flutter frame. Cases have a 60-second
deadline and screenshot requests a 15-second deadline, so a stalled capture
cannot be reported as successful playback. Failed or interrupted runs remain
separate from the subsequent retest evidence.

Fixtures:

- SVGA: the repository's existing decoding fixture is retained; visible playback
  uses Nady's `assets/animations/luck_gift.svga` (five seconds), separately.
- PAG: the repository's `assets/room_gift/combo_button_animation.pag`.
- VAP: Nady's `assets/animations/bg_lucky_bag_open.mp4`, without dynamic slots.
- Plain MP4: a two-second FFmpeg test pattern with a tone, generated locally;
  the production player must mute it before playback.
- Close and fallback artwork: existing room assets, copied unchanged.

These are technical decoder/lifecycle fixtures, not substitutes for full-screen
designs, dynamic gift/user slots, real gift events, another account/device, iOS,
or subjective visual/audio approval. No historical screenshot baseline is updated.
Capture now renders an empty Flutter scene before converting its surface, then
mounts the native player. This avoids resetting an already-playing decoder while
also avoiding the unrendered launch-surface problem above. Lucky loops allow up to
four actual screenshots to sample past intentionally transparent frames; all
samples are retained with retry suffixes, and the same visible-pixel threshold
must be met. A blank frame is never accepted or substituted for a passing frame.

Screenshots and the run report are written under `build/native_qa_evidence` in the
temporary project. Host Flutter, cached package versions and local Nady assets
are prerequisites; a missing dependency or device is reported rather than passed.
