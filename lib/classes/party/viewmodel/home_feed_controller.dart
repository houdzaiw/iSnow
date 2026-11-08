import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/home_feed_session.dart';
import '../../../model/country_info.dart';
import '../home_feed_repository.dart';
import '../model/home_feed_model.dart';
import '../model/home_json.dart';
import 'home_list_view_model.dart';

final homeFeedProvider =
    StateNotifierProvider<HomeFeedViewModel, HomeFeedState>((ref) {
      ref.watch(homeFeedSessionProvider.select((v) => v.generation));
      return HomeFeedViewModel(ref.watch(homeFeedRepositoryProvider));
    });

final homeCountryRoomsProvider =
    StateNotifierProvider.family<
      HomeListViewModel<HomeRoomItem>,
      HomeListState<HomeRoomItem>,
      String?
    >((ref, code) {
      ref.watch(homeFeedSessionProvider.select((v) => v.generation));
      final repo = ref.watch(homeFeedRepositoryProvider);
      return HomeListViewModel(
        (_) => repo.fetchRecommendRooms(countryCode: code),
      );
    });

class HomeFeedState {
  const HomeFeedState({
    this.banners = const [],
    this.countries = const [],
    this.countriesLoading = true,
    this.countriesError,
    this.selectedCountryCode,
  });
  final List<HomeBannerItem> banners;
  final List<CountryInfo> countries;
  final bool countriesLoading;
  final String? countriesError, selectedCountryCode;
}

class HomeFeedViewModel extends StateNotifier<HomeFeedState> {
  HomeFeedViewModel(this._repo) : super(const HomeFeedState()) {
    Future.microtask(() {
      refreshCountries();
      _loadBanners();
    });
  }
  final HomeFeedRepository _repo;
  Future<void>? _countriesRequest;

  void selectCountry(String? code) {
    if (!mounted) return;
    final normalized = normalizeHomeCountryCode(code);
    if (normalized != null &&
        !state.countries.any((c) => c.isoCode == normalized)) {
      return;
    }
    state = HomeFeedState(
      banners: state.banners,
      countries: state.countries,
      countriesLoading: state.countriesLoading,
      countriesError: state.countriesError,
      selectedCountryCode: normalized,
    );
  }

  Future<void> refreshCountries() =>
      _countriesRequest ??= _loadCountries().whenComplete(() {
        _countriesRequest = null;
      });

  Future<void> _loadCountries() async {
    if (!mounted) return;
    state = HomeFeedState(
      banners: state.banners,
      countries: state.countries,
      selectedCountryCode: state.selectedCountryCode,
    );
    try {
      final countries = await _repo.fetchHomeCountries();
      if (!mounted) return;
      final selected = state.selectedCountryCode;
      state = HomeFeedState(
        banners: state.banners,
        countries: countries,
        countriesLoading: false,
        selectedCountryCode: countries.any((c) => c.isoCode == selected)
            ? selected
            : null,
      );
    } catch (error) {
      if (!mounted) return;
      state = HomeFeedState(
        banners: state.banners,
        countries: state.countries,
        countriesLoading: false,
        selectedCountryCode: state.selectedCountryCode,
        countriesError: userFacingErrorMessage(error),
      );
    }
  }

  Future<void> _loadBanners() async {
    if (!mounted) return;
    try {
      final banners = await _repo.fetchBanners();
      if (!mounted) return;
      state = HomeFeedState(
        banners: banners,
        countries: state.countries,
        countriesLoading: state.countriesLoading,
        countriesError: state.countriesError,
        selectedCountryCode: state.selectedCountryCode,
      );
    } catch (_) {
      /* Keep the existing local banner fallback. */
    }
  }
}
