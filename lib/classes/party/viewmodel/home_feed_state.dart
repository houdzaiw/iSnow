part of '../party_page.dart';

class _HomeFeedState {
  const _HomeFeedState({
    required this.banners,
    required this.friends,
    required this.hotCountries,
    required this.rooms,
    this.selectedCountryCode,
  });

  final List<_HomeBannerItem> banners;
  final List<_HomeFriendItem> friends;
  final List<CountryInfo> hotCountries;
  final List<_HomeRoomItem> rooms;
  final String? selectedCountryCode;
}
