import '../profile/tools/profile_feature_repository.dart';

class WebShareMaterial {
  const WebShareMaterial(this.title, this.image, this.link);
  final String title, image, link;
  factory WebShareMaterial.fromJson(Map<String, dynamic> j) => WebShareMaterial(
    membershipString(j['title']),
    membershipString(j['imageUrl']),
    membershipString(j['linkUrl']),
  );
}

class WebShareRequest {
  const WebShareRequest({
    this.materials = const [],
    this.showShare = false,
    this.showRecent = true,
    this.showFriends = true,
  });
  final List<WebShareMaterial> materials;
  final bool showShare, showRecent, showFriends;
  factory WebShareRequest.fromJson(Map<String, dynamic> data) =>
      WebShareRequest(
        materials: membershipList(data['shareList'], WebShareMaterial.fromJson),
        showShare: data['isShowShareTab'] == true,
        showRecent: data['isShowChatTab'] != false,
        showFriends: data['isShowFriendTab'] != false,
      );
}
