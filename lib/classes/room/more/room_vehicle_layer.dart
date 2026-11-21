import 'package:flutter/widgets.dart';

/// Compatibility mount for older room compositions. Entry events and native
/// playback now belong exclusively to RoomGiftEventManager / RoomGiftOverlay.
/// This widget never creates an additional native player or subscription.
@Deprecated('Use the shared RoomGiftOverlay for entrance effects')
class RoomVehicleLayer extends StatelessWidget {
  const RoomVehicleLayer({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
