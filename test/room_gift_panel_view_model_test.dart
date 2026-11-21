import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/gift/models/room_gift_panel_models.dart';
import 'package:project/classes/room/gift/room_gift_repository.dart';
import 'package:project/classes/room/gift/viewmodel/room_gift_panel_view_model.dart';
import 'package:project/model/server_response.dart';

void main() {
  RoomGift gift(int id, {bool lucky = false, RoomJackpotInfo? jackpot}) =>
      RoomGift(
        id: id,
        name: 'gift$id',
        icon: '',
        price: 1,
        isCombo: 1,
        tabId: 1,
        giftType: lucky ? 3 : 1,
        animationUrl: 'https://cdn.example/$id.pag',
        jackpotInfo: jackpot,
      );
  RoomGiftBannerSnapshot record(int giftId, int uid) => RoomGiftBannerSnapshot(
    giftId: giftId,
    senderUid: uid,
    senderName: 'user$uid',
    senderAvatar: '',
    multiple: 10,
    winAmount: 100,
  );

  test(
    'selection and close isolate late banner results and preview completion',
    () async {
      final repo = _Repository()..pending = Completer();
      final vm = RoomGiftPanelViewModel(repo);
      addTearDown(vm.dispose);
      vm.selectGift(gift(1, lucky: true));
      final revision = vm.snapshot.previewRevision;
      final request = vm.retrySnapshots();
      vm.selectGift(gift(2));
      repo.pending!.complete([record(1, 10)]);
      await request;
      expect(vm.snapshot.gift!.id, 2);
      expect(vm.snapshot.snapshots, isEmpty);
      vm.closePreview(revision);
      expect(vm.snapshot.preview!.id, 2);
    },
  );

  testWidgets(
    'three-second rotation pauses while hidden and preview stays closed',
    (tester) async {
      final repo = _Repository()
        ..records = [record(1, 10), record(1, 20), record(1, 30)];
      final vm = RoomGiftPanelViewModel(repo);
      addTearDown(() {
        if (vm.mounted) vm.dispose();
      });
      vm.selectGift(gift(1, lucky: true));
      await tester.pump(const Duration(milliseconds: 201));
      expect(repo.loads, 1);
      expect(vm.snapshot.snapshotIndex, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(vm.snapshot.snapshotIndex, 1);
      vm.setVisible(false);
      await tester.pump(const Duration(seconds: 9));
      expect(vm.snapshot.snapshotIndex, 1);
      expect(vm.snapshot.preview, isNull);
      vm.setVisible(true);
      await tester.pump(const Duration(seconds: 3));
      expect(vm.snapshot.snapshotIndex, 2);
      expect(vm.snapshot.preview, isNull);
      vm.dispose();
      await tester.pump();
    },
  );

  test(
    'SUPER preview is once per panel and owned tasks cancel on selection/dispose',
    () {
      final shown = <String>[], cancelled = <String>[];
      final vm = RoomGiftPanelViewModel(
        _Repository(),
        onSuperSelected: (_, key) => shown.add(key),
        onCancelSuper: cancelled.add,
      );
      const superInfo = RoomJackpotInfo(
        enabled: true,
        mode: 'SUPER',
        displayAmount: 100,
      );
      vm.selectGift(gift(1, lucky: true, jackpot: superInfo));
      final original = shown.single;
      expect(vm.ownsSuperTask(original), isTrue);
      vm.replayPreview();
      vm.selectGift(gift(2));
      expect(vm.ownsSuperTask(original), isFalse);
      vm.selectGift(gift(1, lucky: true, jackpot: superInfo));
      expect(vm.ownsSuperTask(original), isFalse);
      expect(shown, hasLength(1));
      expect(cancelled, [shown.single]);
      expect(vm.snapshot.preview, isNull);
      vm.dispose();
      expect(vm.ownsSuperTask(original), isFalse);
    },
  );

  test('pool events update real amount and trigger a selected SUPER once', () {
    var shown = 0;
    final vm = RoomGiftPanelViewModel(
      _Repository(),
      onSuperSelected: (_, __) => shown++,
    );
    addTearDown(vm.dispose);
    vm.selectGift(gift(1, lucky: true));
    vm.updateJackpots(const {
      1: RoomJackpotInfo(enabled: true, mode: 'SUPER', displayAmount: 123),
    });
    vm.updateJackpots(const {
      1: RoomJackpotInfo(enabled: true, mode: 'SUPER', displayAmount: 456),
    });
    expect(vm.snapshot.jackpot!.displayAmount, 456);
    expect(shown, 1);
  });

  test(
    'resource eviction finishes before replay; close discards late retry',
    () async {
      final eviction = Completer<void>();
      final vm = RoomGiftPanelViewModel(
        _Repository(),
        invalidatePreview: (_) => eviction.future,
      );
      addTearDown(vm.dispose);
      vm.selectGift(gift(1));
      final revision = vm.snapshot.previewRevision;
      final retry = vm.retryPreview();
      expect(vm.snapshot.previewRevision, revision);
      vm.setVisible(false);
      eviction.complete();
      await retry;
      expect(vm.snapshot.preview, isNull);
      expect(vm.snapshot.previewRevision, revision);
    },
  );

  test(
    'busy full-screen lane prevents panel preview and never auto-replays it',
    () {
      final vm = RoomGiftPanelViewModel(_Repository());
      addTearDown(vm.dispose);
      vm.setPlaybackBusy(true);
      vm.selectGift(gift(1));
      expect(vm.snapshot.preview, isNull);
      vm.setPlaybackBusy(false);
      expect(vm.snapshot.preview, isNull);
      vm.replayPreview();
      expect(vm.snapshot.preview!.id, 1);
    },
  );

  test(
    'snapshot failures retain server message and retry is independent of sending',
    () async {
      final repo = _Repository()
        ..failure = const NadyApiException(message: 'Actual server msg');
      final vm = RoomGiftPanelViewModel(repo);
      addTearDown(vm.dispose);
      vm.selectGift(gift(1, lucky: true));
      await vm.retrySnapshots();
      expect(vm.snapshot.error, 'Actual server msg');
      repo.failure = null;
      repo.records = [record(1, 20)];
      await vm.retrySnapshots();
      expect(vm.snapshot.snapshot!.senderUid, 20);
      expect(repo.sent, 0);
    },
  );
}

class _Repository extends RoomGiftRepository {
  Completer<List<RoomGiftBannerSnapshot>>? pending;
  List<RoomGiftBannerSnapshot> records = const [];
  Object? failure;
  int loads = 0, sent = 0;
  @override
  Future<List<RoomGiftBannerSnapshot>> fetchLuckySnapshots(int giftId) async {
    loads++;
    if (failure != null) throw failure!;
    return pending == null ? records : pending!.future;
  }

  @override
  Future<RoomGiftCatalog> fetchCatalog() async =>
      const RoomGiftCatalog(balance: 100, canSendSelf: true, tabs: []);
  @override
  Future<int> fetchBalance() async => 100;
  @override
  Future<RoomGiftSendResult> sendGift(SendRoomGiftRequest request) async {
    sent++;
    return const RoomGiftSendResult();
  }
}
