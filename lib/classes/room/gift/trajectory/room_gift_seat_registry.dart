import 'package:flutter/widgets.dart';

class RoomGiftSeatCoordinate {
  const RoomGiftSeatCoordinate({
    required this.uid,
    required this.position,
    required this.offset,
  });
  final int uid, position;
  final Offset offset;
}

/// Presentation-only coordinates relative to the room's effect Stack.
class RoomGiftSeatRegistry {
  RoomGiftSeatRegistry(this.rootKey);
  final GlobalKey rootKey;
  final Map<int, ({int position, GlobalKey key})> _anchors = {};
  GlobalKey? _originKey;

  void registerOrigin(GlobalKey key) => _originKey = key;

  void unregisterOrigin(GlobalKey key) {
    if (_originKey == key) _originKey = null;
  }

  void register(int uid, int position, GlobalKey key) {
    if (uid > 0) _anchors[uid] = (position: position, key: key);
  }

  void unregister(int uid, GlobalKey key) {
    if (_anchors[uid]?.key == key) _anchors.remove(uid);
  }

  RoomGiftSeatCoordinate? coordinate(int uid) {
    final anchor = _anchors[uid];
    final offset = _center(anchor?.key);
    if (anchor == null || offset == null) return null;
    return RoomGiftSeatCoordinate(
      uid: uid,
      position: anchor.position,
      offset: offset,
    );
  }

  RoomGiftSeatCoordinate? sourceCoordinate(int uid) {
    final seat = coordinate(uid);
    if (seat != null) return seat;
    final offset = _center(_originKey);
    return offset == null
        ? null
        : RoomGiftSeatCoordinate(uid: uid, position: -1, offset: offset);
  }

  Offset? _center(GlobalKey? key) {
    final root = rootKey.currentContext?.findRenderObject();
    final box = key?.currentContext?.findRenderObject();
    if (root is! RenderBox ||
        box is! RenderBox ||
        !root.attached ||
        !box.attached ||
        !box.hasSize) {
      return null;
    }
    return root.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }
}

class RoomGiftSeatScope extends InheritedWidget {
  const RoomGiftSeatScope({
    super.key,
    required this.registry,
    required super.child,
  });
  final RoomGiftSeatRegistry registry;
  static RoomGiftSeatRegistry? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RoomGiftSeatScope>()?.registry;
  @override
  bool updateShouldNotify(RoomGiftSeatScope oldWidget) =>
      registry != oldWidget.registry;
}

class RoomGiftSeatAnchor extends StatefulWidget {
  const RoomGiftSeatAnchor({
    super.key,
    required this.uid,
    required this.position,
    required this.child,
    this.isOrigin = false,
  });
  final int? uid;
  final int position;
  final Widget child;
  final bool isOrigin;
  @override
  State<RoomGiftSeatAnchor> createState() => _RoomGiftSeatAnchorState();
}

class _RoomGiftSeatAnchorState extends State<RoomGiftSeatAnchor> {
  final _key = GlobalKey();
  RoomGiftSeatRegistry? _registry;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unregister(widget.uid);
    _registry = RoomGiftSeatScope.of(context);
    _register();
  }

  @override
  void didUpdateWidget(RoomGiftSeatAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregister(oldWidget.uid);
    _register();
  }

  void _register() {
    if (widget.isOrigin) {
      _registry?.registerOrigin(_key);
    } else if (widget.uid != null) {
      _registry?.register(widget.uid!, widget.position, _key);
    }
  }

  void _unregister(int? uid) {
    _registry?.unregisterOrigin(_key);
    if (uid != null) _registry?.unregister(uid, _key);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(key: _key, child: widget.child);
  @override
  void dispose() {
    _unregister(widget.uid);
    super.dispose();
  }
}
