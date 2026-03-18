import 'dart:convert';
import 'dart:ffi';
import 'package:sp_util/sp_util.dart';
import '../model/login_model.dart';

/// Key names used for SharedPreferences via sp_util
const _kLoginModel = 'login_model';
const _kToken = 'token';

/// Singleton that owns the current user session.
/// - Call [saveLogin] after a successful login.
/// - Call [logout] to clear the session.
/// - Call [restore] once at app launch to reload a persisted session.
/// - Read [currentUser] / [token] / [isLoggedIn] anywhere without context.
class UserManager {
  UserManager._();

  static final UserManager shared = UserManager._();

  LoginModel? _currentUser;

  /// The currently logged-in user, or null if not logged in.
  LoginModel? get currentUser => _currentUser;

  /// Shortcut for the auth token.
  String? get token => _currentUser?.token;
  String? get nick => _currentUser?.userBaseInfo?.nick;
  int? get userId => _currentUser?.uid ?? _currentUser?.userBaseInfo?.uid ?? 0;
  String? get avatar => _currentUser?.userBaseInfo?.avatar;

  /// Whether a user session is active.
  bool get isLoggedIn => _currentUser != null && (_currentUser!.token.isNotEmpty);

  // ── Persist / restore ────────────────────────────────────────────────────

  /// Persist login data to local storage and update the in-memory cache.
  Future<void> saveLogin(LoginModel model) async {
    _currentUser = model;
    await SpUtil.putString(_kToken, model.token);
    await SpUtil.putString(_kLoginModel, jsonEncode(model.toJson()));
  }

  /// Load a previously saved session from local storage.
  /// Call this once during app initialisation (before routing).
  Future<void> restore() async {
    final raw = SpUtil.getString(_kLoginModel);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _currentUser = LoginModel.fromJson(json);
      } catch (_) {
        // Corrupt data — clear it
        await logout();
      }
    }
  }

  /// Clear the session from memory and local storage.
  Future<void> logout() async {
    _currentUser = null;
    await SpUtil.remove(_kToken);
    await SpUtil.remove(_kLoginModel);
  }
}

