import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/api_error_message.dart';
import '../../../../theme/app_assets.dart';
import '../effects/room_gift_asset_resolver.dart';
import '../event/room_gift_event_manager.dart';
import '../event/room_gift_event_provider.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_models.dart';
import '../models/room_gift_panel_models.dart';
import '../room_gift_repository.dart';
import 'room_gift_view_model.dart';

final roomGiftPanelViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomGiftPanelViewModel, RoomGiftPanelState, String>((ref, roomId) {
      late final RoomGiftPanelViewModel model;
      final eventManager = ref.read(
        roomGiftEventManagerProvider(roomId).notifier,
      );
      model = RoomGiftPanelViewModel(
        ref.watch(roomGiftRepositoryProvider),
        invalidatePreview: (gift) async {
          await ref.read(roomGiftAssetResolverProvider).evict(gift);
          if (model.mounted) ref.invalidate(roomGiftAnimationProvider(gift));
        },
        onCancelSuper: eventManager.cancelFullscreen,
        onSuperSelected: (gift, key) => Future.microtask(() {
          if (!model.ownsSuperTask(key) ||
              ref.read(roomGiftViewModelProvider(roomId)).selectedGift?.id !=
                  gift.id) {
            return;
          }
          eventManager.enqueueFullscreen(
            RoomGiftEffectTask(
              key: key,
              createdAt: DateTime.now(),
              kind: RoomGiftEffectKind.preview,
              giftIcon: gift.icon,
              message: RoomScreenGiftMsg(
                gift: const RoomGift(
                  id: -2,
                  name: 'Jackpot',
                  icon: '',
                  price: 0,
                  isCombo: 0,
                  tabId: 0,
                  animationUrl: AppAssets.roomGiftJackpotEffect,
                ),
                uid: eventManager.currentUid ?? 0,
                userInfo: RoomGiftUser(uid: eventManager.currentUid ?? 0),
                roomId: roomId,
                giftCount: 1,
              ),
            ),
          );
        }),
      );
      ref.listen(roomGiftViewModelProvider(roomId), (previous, next) {
        if (previous?.selectedGiftKey != next.selectedGiftKey) {
          model.selectGift(next.selectedGift);
        }
      }, fireImmediately: true);
      ref.listen(
        roomGiftEventManagerProvider(roomId).select((value) => value.jackpots),
        (_, next) => model.updateJackpots(next),
        fireImmediately: true,
      );
      ref.listen(
        roomGiftEventManagerProvider(
          roomId,
        ).select((value) => value.effects.isNotEmpty || value.canPlayLucky),
        (_, busy) => model.setPlaybackBusy(busy),
        fireImmediately: true,
      );
      return model;
    });

class RoomGiftPanelState {
  const RoomGiftPanelState({
    this.gift,
    this.preview,
    this.previewRevision = 0,
    this.snapshots = const [],
    this.snapshotIndex = 0,
    this.loading = false,
    this.error,
    this.jackpot,
  });
  final RoomGift? gift, preview;
  final RoomJackpotInfo? jackpot;
  final int previewRevision, snapshotIndex;
  final List<RoomGiftBannerSnapshot> snapshots;
  final bool loading;
  final String? error;
  RoomGiftBannerSnapshot? get snapshot =>
      snapshots.isEmpty ? null : snapshots[snapshotIndex % snapshots.length];
  RoomGiftPanelState copyWith({
    Object? preview = _unset,
    int? previewRevision,
    List<RoomGiftBannerSnapshot>? snapshots,
    int? snapshotIndex,
    bool? loading,
    Object? error = _unset,
    RoomJackpotInfo? jackpot,
  }) => RoomGiftPanelState(
    gift: gift,
    preview: identical(preview, _unset) ? this.preview : preview as RoomGift?,
    previewRevision: previewRevision ?? this.previewRevision,
    snapshots: snapshots ?? this.snapshots,
    snapshotIndex: snapshotIndex ?? this.snapshotIndex,
    loading: loading ?? this.loading,
    error: identical(error, _unset) ? this.error : error as String?,
    jackpot: jackpot ?? this.jackpot,
  );
}

const _unset = Object();

/// Panel-only selection, preview and record rotation. Never sends gifts.
class RoomGiftPanelViewModel extends StateNotifier<RoomGiftPanelState> {
  RoomGiftPanelViewModel(
    this.repository, {
    this.invalidatePreview,
    this.onSuperSelected,
    this.onCancelSuper,
  }) : super(const RoomGiftPanelState());
  final RoomGiftRepository repository;
  final Future<void> Function(RoomGift)? invalidatePreview;
  final void Function(RoomGift, String)? onSuperSelected;
  final void Function(String)? onCancelSuper;
  final _shownSuper = <int>{};
  final _superTasks = <String>{};
  final _instance = DateTime.now().microsecondsSinceEpoch;
  Map<int, RoomJackpotInfo> _jackpots = const {};
  Timer? _rotation, _debounce;
  bool _visible = true;
  bool _playbackBusy = false, _retrying = false;
  int _epoch = 0;
  bool get isVisible => _visible;

  /// A deferred start must retain its panel's live ownership ticket.
  bool ownsSuperTask(String key) =>
      mounted && _visible && _superTasks.contains(key);
  bool get canAnimatePanel =>
      _visible && !_playbackBusy && state.preview == null;
  RoomGiftPanelState get snapshot => state;

  void selectGift(RoomGift? gift) {
    if (!mounted) return;
    _epoch++;
    _cancelSupers();
    _rotation?.cancel();
    _debounce?.cancel();
    final jackpot = _jackpots[gift?.id] ?? gift?.jackpotInfo;
    state = RoomGiftPanelState(
      gift: gift,
      jackpot: jackpot,
      previewRevision: state.previewRevision + 1,
      preview:
          _visible &&
              !_playbackBusy &&
              jackpot?.isSuper != true &&
              _canPreview(gift)
          ? gift
          : null,
    );
    _showSuper();
    if (gift?.giftType == 3) {
      _debounce = Timer(
        const Duration(milliseconds: 200),
        () => unawaited(retrySnapshots()),
      );
    }
  }

  bool _canPreview(RoomGift? gift) {
    if (gift == null) return false;
    if (AppAssets.roomGiftLocalAnimations.containsKey(gift.id)) return true;
    final uri = Uri.tryParse(gift.animationUrl ?? '');
    return uri != null &&
        uri.hasAuthority &&
        uri.userInfo.isEmpty &&
        ['http', 'https'].contains(uri.scheme) &&
        ['.svga', '.pag', '.mp4', '.vap'].any(uri.path.toLowerCase().endsWith);
  }

  void replayPreview() {
    if (mounted && state.gift?.giftType == 3 && state.snapshots.isEmpty) {
      unawaited(retrySnapshots());
    }
    if (!mounted ||
        !_visible ||
        _playbackBusy ||
        !_canPreview(state.gift) ||
        state.jackpot?.isSuper == true) {
      return;
    }
    state = state.copyWith(
      preview: state.gift,
      previewRevision: state.previewRevision + 1,
    );
  }

  Future<void> retryPreview() async {
    if (!mounted || _retrying || state.gift == null) return;
    final epoch = _epoch;
    _retrying = true;
    try {
      await invalidatePreview?.call(state.gift!);
      if (mounted && epoch == _epoch) replayPreview();
    } catch (_) {
      /* Keep the visible retry state. */
    } finally {
      _retrying = false;
    }
  }

  void setPlaybackBusy(bool value) {
    if (!mounted || value == _playbackBusy) return;
    _playbackBusy = value;
    if (value) {
      closePreview();
    } else {
      state = state.copyWith();
    }
  }

  void closePreview([int? revision]) {
    if (mounted && (revision == null || revision == state.previewRevision)) {
      state = state.copyWith(preview: null);
    }
  }

  void updateJackpots(Map<int, RoomJackpotInfo> values) {
    _jackpots = values;
    final value = values[state.gift?.id];
    if (mounted && value != null) {
      state = state.copyWith(jackpot: value);
      _showSuper();
    }
  }

  void _showSuper() {
    final gift = state.gift;
    if (!_visible ||
        gift == null ||
        state.jackpot?.isSuper != true ||
        !_shownSuper.add(gift.id)) {
      return;
    }
    state = state.copyWith(preview: null);
    final key = 'panel-super-$_instance-${gift.id}';
    _superTasks.add(key);
    onSuperSelected?.call(gift, key);
  }

  void _cancelSupers() {
    for (final key in _superTasks) {
      onCancelSuper?.call(key);
    }
    _superTasks.clear();
  }

  Future<void> retrySnapshots() async {
    if (!mounted || !_visible || state.gift?.giftType != 3 || state.loading) {
      return;
    }
    final epoch = _epoch, giftId = state.gift!.id;
    state = state.copyWith(loading: true, error: null);
    try {
      final snapshots = await repository.fetchLuckySnapshots(giftId);
      if (!mounted || epoch != _epoch || !_visible) return;
      state = state.copyWith(
        snapshots: snapshots,
        snapshotIndex: 0,
        loading: false,
      );
      _rotate();
    } catch (error) {
      if (mounted && epoch == _epoch && _visible) {
        state = state.copyWith(
          loading: false,
          error: userFacingErrorMessage(error),
        );
      }
    }
  }

  void setVisible(bool value) {
    if (!mounted || _visible == value) return;
    _visible = value;
    _rotation?.cancel();
    _debounce?.cancel();
    if (!value) {
      _cancelSupers();
      _epoch++;
      state = state.copyWith(preview: null, loading: false);
    } else {
      state = state.copyWith();
      _showSuper();
      _rotate();
      if (state.snapshots.isEmpty) unawaited(retrySnapshots());
    }
  }

  void _rotate() {
    _rotation?.cancel();
    if (!_visible || state.snapshots.length < 2) return;
    _rotation = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _visible) {
        state = state.copyWith(
          snapshotIndex: (state.snapshotIndex + 1) % state.snapshots.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _cancelSupers();
    _epoch++;
    _rotation?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
