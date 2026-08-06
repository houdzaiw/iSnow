part of 'party_page.dart';

final _homeFeedViewModelProvider =
    AsyncNotifierProvider<_HomeFeedViewModel, _HomeFeedState>(
      _HomeFeedViewModel.new,
    );

class _HomeFeedViewModel extends AsyncNotifier<_HomeFeedState> {
  String? _selectedCountryCode;

  @override
  Future<_HomeFeedState> build() {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refreshFeed() {
    return reload();
  }

  Future<void> selectCountry(String? countryCode) async {
    final normalizedCode = countryCode?.toUpperCase();
    if (state.hasValue && _selectedCountryCode == normalizedCode) return;

    _selectedCountryCode = normalizedCode;
    await reload();
  }

  Future<_HomeFeedState> _load() async {
    final repository = ref.read(_homeFeedRepositoryProvider);
    final bannersFuture = _loadSection<List<_HomeBannerItem>>(
      name: HttpApi.homeResourceBanner,
      loader: repository.fetchBanners,
      fallback: const <_HomeBannerItem>[],
    );
    final friendsFuture = _loadSection<List<_HomeFriendItem>>(
      name: HttpApi.friendPlayingList,
      loader: repository.fetchFriendsPlaying,
      fallback: const <_HomeFriendItem>[],
    );

    final hotCountriesResult = await _loadSection<List<CountryInfo>>(
      name: HttpApi.hotCountry,
      loader: repository.fetchHotCountries,
      fallback: const <CountryInfo>[],
    );
    final hotCountries = hotCountriesResult.value;
    final countryCode = hotCountriesResult.isSuccess
        ? _validCountryCode(hotCountries)
        : _clearSelectedCountryCode();

    final roomsResult = hotCountriesResult.isSuccess
        ? await _loadSection<List<_HomeRoomItem>>(
            name: HttpApi.homeRecommendRoom,
            loader: () =>
                repository.fetchRecommendRooms(countryCode: countryCode),
            fallback: const <_HomeRoomItem>[],
          )
        : const _HomeFeedCallResult<List<_HomeRoomItem>>(
            value: <_HomeRoomItem>[],
            isSuccess: false,
          );
    final bannersResult = await bannersFuture;
    final friendsResult = await friendsFuture;

    return _HomeFeedState(
      banners: bannersResult.value,
      friends: friendsResult.value,
      hotCountries: hotCountries,
      rooms: roomsResult.value,
      selectedCountryCode: countryCode,
    );
  }

  String? _validCountryCode(List<CountryInfo> hotCountries) {
    final selectedCountryCode = _selectedCountryCode;
    final hasCountry =
        selectedCountryCode != null &&
        hotCountries.any(
          (country) => country.isoCode.toUpperCase() == selectedCountryCode,
        );
    _selectedCountryCode = hasCountry ? selectedCountryCode : null;
    return _selectedCountryCode;
  }

  String? _clearSelectedCountryCode() {
    _selectedCountryCode = null;
    return null;
  }

  Future<_HomeFeedCallResult<T>> _loadSection<T>({
    required String name,
    required Future<T> Function() loader,
    required T fallback,
  }) async {
    try {
      return _HomeFeedCallResult<T>(value: await loader(), isSuccess: true);
    } catch (error, stackTrace) {
      debugPrint('[HomeFeed] $name failed: $error\n$stackTrace');
      return _HomeFeedCallResult<T>(value: fallback, isSuccess: false);
    }
  }
}

class _HomeFeedCallResult<T> {
  const _HomeFeedCallResult({required this.value, required this.isSuccess});

  final T value;
  final bool isSuccess;
}
